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

if (!Number.isInteger(porta) || porta <= 0) {
  throw new Error('SERVIDOR_PORTA deve ser um número inteiro positivo.');
}

// ETAPA 2 — REGRA DA LEITURA
function ehCodigoPostal(codigo) {
  const tamanhoCorreto = codigo.length === 13 || codigo.length === 14;
  return tamanhoCorreto && codigo.toUpperCase().endsWith('BR');
}

function erroDeValidacao(mensagem) {
  return Object.assign(new Error(mensagem), { statusCode: 400 });
}

// ETAPA 3 — VALIDAÇÃO E GRAVAÇÃO
async function salvarLeitura(codigoRecebido) {
  const codigo = String(codigoRecebido ?? '').trim();

  if (!codigo) {
    throw erroDeValidacao('O campo codigo é obrigatório.');
  }

  if (ehCodigoPostal(codigo)) {
    await databasePool.execute(
      'INSERT INTO portalpostal.saida_objetos_temp (codigo) VALUES (?)',
      [codigo],
    );
    return { codigo, destino: 'portalpostal.saida_objetos_temp' };
  }

  // OBS: pev_num é INT, por isso aceita somente números dentro desse limite.
  if (!/^\d+$/.test(codigo)) {
    throw erroDeValidacao('O número do pedido deve conter somente dígitos.');
  }

  if (BigInt(codigo) > 2147483647n) {
    throw erroDeValidacao('O número do pedido ultrapassa o limite da coluna INT.');
  }

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
