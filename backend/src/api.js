import cors from 'cors';
import { config } from 'dotenv';
import express from 'express';
import { fileURLToPath } from 'node:url';

// OBS: utiliza a conexão configurada em database/.env.
import { databasePool } from '../../database/src/connection.js';

// ETAPA 1 — CONFIGURAÇÃO
config({ path: fileURLToPath(new URL('../.env', import.meta.url)) });

const host = process.env.SERVIDOR_HOST || '0.0.0.0';
const porta = Number(process.env.SERVIDOR_PORTA || 3001);

// OBS: este é o APK que o celular poderá baixar pela rede local.
const caminhoDoApk = fileURLToPath(
  new URL('../../build/app/outputs/flutter-apk/app-debug.apk', import.meta.url),
);

if (!Number.isInteger(porta) || porta <= 0) {
  throw new Error('SERVIDOR_PORTA deve ser um número inteiro positivo.');
}

// ETAPA 2 — REGRA DA LEITURA
function ehCodigoPostal(codigo) {
  const tamanhoCorreto = codigo.length === 13;
  return tamanhoCorreto && codigo.toUpperCase().endsWith('BR');
}

function ehPedidoDeVenda(codigo) {
  return /^\d{5,6}$/.test(codigo);
}

const destinos = {
  portalPostal: {
    nome: 'portalpostal.saida_objetos_temp',
    rotulo: 'Portal Postal',
    consultar:
      'SELECT 1 FROM portalpostal.saida_objetos_temp WHERE codigo = ? LIMIT 1',
    inserir:
      'INSERT INTO portalpostal.saida_objetos_temp (codigo) VALUES (?)',
  },
  pedidoDeVenda: {
    nome: 'talmax.pedido_de_venda_saida_temp',
    rotulo: 'Pedido de Venda',
    consultar:
      'SELECT 1 FROM talmax.pedido_de_venda_saida_temp WHERE pev_num = ? LIMIT 1',
    inserir:
      'INSERT INTO talmax.pedido_de_venda_saida_temp (pev_num) VALUES (?)',
  },
};

function normalizarCodigo(codigoRecebido) {
  // Remove caracteres invisíveis enviados por alguns códigos Data Matrix.
  const semControles = String(codigoRecebido ?? '')
    .replace(/[\x00-\x1F\x7F]/g, ' ')
    .trim();
  // Alguns leitores acrescentam o identificador AIM "]d2" ao Data Matrix.
  const codigo = semControles.replace(/^\][A-Za-z]\d/, '');

  if (ehCodigoPostal(codigo)) return codigo;

  // OBS: aceita o pedido dentro de um prefixo somente quando há uma opção.
  const gruposNumericos = codigo.match(/\d+/g) || [];
  const pedidosPossiveis = gruposNumericos.filter(ehPedidoDeVenda);
  if (pedidosPossiveis.length === 1) return pedidosPossiveis[0];

  throw erroDeValidacao('');
}

function criarErro(mensagem, statusCode) {
  return Object.assign(new Error(mensagem), { statusCode });
}

function erroDeValidacao(mensagem) {
  return criarErro(mensagem, 400);
}

async function existePedidoCancelado(codigo, chaveNatural) {
  if (chaveNatural === 'pedidoDeVenda') {
    const [cancelados] = await databasePool.execute(
      `SELECT 1
        FROM talmax.pedido_de_venda
        WHERE pev_num = ?
          AND pev_ativo = 0
        LIMIT 1`,
      [codigo],
    );
    return cancelados.length > 0;
  }

  const [cancelados] = await databasePool.execute(
    `SELECT 1
      FROM portalpostal.prepostagem pp
      LEFT JOIN talmax.numped np_ped ON np_ped.numped = pp.chave
      LEFT JOIN talmax.numped np_orc ON np_orc.numorc = np_ped.numped
      JOIN talmax.pedido_de_venda pv ON pv.pev_num = np_orc.numped
      WHERE pp.codigorastreio = ?
        AND pv.pev_ativo = 0
      LIMIT 1`,
    [codigo],
  );
  return cancelados.length > 0;
}

// ETAPA 3 — VALIDAÇÃO E GRAVAÇÃO
async function salvarLeitura(codigoRecebido, modoEscolhido) {
  // REGRA 1 - CÓDIGO VÁLIDO:
  // Aceita somente rastreio postal ou pedido de venda nos formatos definidos
  // em normalizarCodigo. Qualquer outro conteúdo não chega ao banco.
  const codigo = normalizarCodigo(codigoRecebido);
  const chaveNatural = ehCodigoPostal(codigo) ? 'portalPostal' : 'pedidoDeVenda';

  // REGRA 1.1 - MODO ESCOLHIDO PELO BOTÃO:
  // Quando o app informa o modo, o formato do código precisa bater com ele.
  if (modoEscolhido && modoEscolhido !== chaveNatural) {
    const outro = destinos[chaveNatural].rotulo;
    throw erroDeValidacao(`Este código é de ${outro}. Abra o modo ${outro}.`);
  }

  const destino = destinos[modoEscolhido ?? chaveNatural];

  if (await existePedidoCancelado(codigo, chaveNatural)) {
    throw criarErro('Pedido cancelado. Esta leitura não pode ser salva.', 409);
  }

  if (ehCodigoPostal(codigo)) {
    // REGRA 2 - RASTREIO JÁ UTILIZADO:
    // Não permite inserir na tabela temporária um rastreio que já aparece
    // na tabela definitiva portalpostal.saida_objetos.
    const [rastreamentosUtilizados] = await databasePool.execute(
      `SELECT 1
        FROM portalpostal.saida_objetos
        WHERE codigorastreio = ?
        LIMIT 1`,
      [codigo],
    );

    if (rastreamentosUtilizados.length > 0) {
      throw criarErro('Código de rastreio já utilizado!', 409);
    }
  }

  // REGRA 3 - NÃO BIPAR DUAS VEZES:
  // Procura o código na tabela temporária correta. Se ele já existir,
  // devolve HTTP 409 e não executa um novo INSERT.
  const [existentes] = await databasePool.execute(destino.consultar, [codigo]);
  if (existentes.length > 0) {
    throw criarErro('Este código já foi bipado anteriormente.', 409);
  }

  // REGRA 4 - GRAVAÇÃO CONFIRMADA:
  // O código só é inserido quando passou por todas as regras anteriores.
  await databasePool.execute(destino.inserir, [codigo]);
  return { codigo, destino: destino.nome };
}

// ETAPA 4 — ROTAS DA API
const api = express();
api.use(cors());
api.use(express.json({ limit: '32kb' }));

// Apenas verifica a API e o banco; não grava dados.
api.get('/saude', async (_requisicao, resposta) => {
  await databasePool.query('SELECT 1');
  resposta.json({ backend: 'ok', banco: 'ok' });
});

// Baixa o APK pelo navegador do celular; não acessa nem altera o banco.
api.get('/baixar-apk', (_requisicao, resposta, proximo) => {
  resposta.download(caminhoDoApk, 'expedicao.apk', (erro) => {
    if (erro && !resposta.headersSent) proximo(erro);
  });
});

// Recebe: { "codigo": "CONTEUDO_LIDO", "modo": "pedidoDeVenda" | "portalPostal" }.
// O "modo" é opcional; sem ele, o destino é escolhido pelo formato do código.
api.post('/leituras', async (requisicao, resposta) => {
  const modoRecebido = requisicao.body?.modo;
  if (modoRecebido !== undefined && !Object.hasOwn(destinos, modoRecebido)) {
    throw erroDeValidacao('Modo inválido. Use "pedidoDeVenda" ou "portalPostal".');
  }
  const leitura = await salvarLeitura(requisicao.body?.codigo, modoRecebido);
  resposta.status(201).json({
    mensagem: 'Leitura salva com sucesso.',
    ...leitura,
  });
});

api.use((erro, _requisicao, resposta, _proximo) => {
  console.error(erro);
  resposta.status(erro.statusCode || 500).json({
    erro: erro.statusCode ? erro.message : 'Erro interno do servidor.',
  });
});

// ETAPA 5 — INICIALIZAÇÃO
api.listen(porta, host, () => {
  console.log(`API disponível em http://${host}:${porta}`);
});
