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

  throw erroDeValidacao(
    'Código inválido: não foi possível identificar um único pedido.',
  );
}

function erroDeValidacao(mensagem) {
  return Object.assign(new Error(mensagem), { statusCode: 400 });
}

function erroDeDuplicidade() {
  return Object.assign(new Error('Este código já foi bipado anteriormente.'), {
    statusCode: 409,
  });
}

// ETAPA 3 — VALIDAÇÃO E GRAVAÇÃO
async function salvarLeitura(codigoRecebido) {
  if (!String(codigoRecebido ?? '').trim()) {
    throw erroDeValidacao('O campo codigo é obrigatório.');
  }

  const codigo = normalizarCodigo(codigoRecebido);

  if (ehCodigoPostal(codigo)) {
    // OBS: não grava novamente um código que já existe no Portal Postal.
    const [existentes] = await databasePool.execute(
      'SELECT 1 FROM portalpostal.saida_objetos_temp WHERE codigo = ? LIMIT 1',
      [codigo],
    );
    if (existentes.length > 0) throw erroDeDuplicidade();

    await databasePool.execute(
      'INSERT INTO portalpostal.saida_objetos_temp (codigo) VALUES (?)',
      [codigo],
    );
    return { codigo, destino: 'portalpostal.saida_objetos_temp' };
  }

  // OBS: pedido de venda deve ter somente 5 ou 6 dígitos.
  if (!ehPedidoDeVenda(codigo)) {
    throw erroDeValidacao(
      'Código inválido: use 13 caracteres terminando em BR ou 5 a 6 dígitos.',
    );
  }

  // OBS: não grava novamente um pedido que já existe na tabela temporária.
  const [existentes] = await databasePool.execute(
    'SELECT 1 FROM talmax.pedido_de_venda_saida_temp WHERE pev_num = ? LIMIT 1',
    [codigo],
  );
  if (existentes.length > 0) throw erroDeDuplicidade();

  await databasePool.execute(
    'INSERT INTO talmax.pedido_de_venda_saida_temp (pev_num) VALUES (?)',
    [codigo],
  );
  return { codigo, destino: 'talmax.pedido_de_venda_saida_temp' };
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

// Recebe: { "codigo": "CONTEUDO_LIDO" }.
api.post('/leituras', async (requisicao, resposta) => {
  const leitura = await salvarLeitura(requisicao.body?.codigo);
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
