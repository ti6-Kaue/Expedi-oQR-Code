// Configuracao principal do servidor Express.
// Observacao: registra recursos comuns, rotas HTTP e tratamento de erros.
// Comunica-se com: database.js, routes/scans.js e server.js.
import cors from 'cors';
import express from 'express';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { pool } from './database.js';
import { scansRouter } from './routes/scans.js';

export const app = express();

// Localiza o APK gerado pelo Flutter para disponibiliza-lo na rota /download.
const currentDirectory = dirname(fileURLToPath(import.meta.url));
const apkPath = resolve(
  currentDirectory,
  '..',
  '..',
  'build',
  'app',
  'outputs',
  'flutter-apk',
  'app-release.apk',
);

// CORS permite que a versao web do aplicativo acesse esta API.
app.use(cors());

// Converte automaticamente requisicoes JSON em request.body.
// O limite pequeno protege a API contra envios muito grandes.
app.use(express.json({ limit: '64kb' }));

// GET /
// Observacao: mostra uma pagina simples com o link para baixar o APK.
app.get('/', (request, response) => {
  response.type('html').send(`
    <!doctype html>
    <html lang="pt-BR">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Leitor QR Code</title>
      </head>
      <body style="font-family: sans-serif; text-align: center; padding: 40px">
        <h1>Leitor QR Code</h1>
        <p>Baixe o aplicativo para Android.</p>
        <a href="/download" style="font-size: 20px">Baixar APK</a>
      </body>
    </html>
  `);
});

// GET /download
// Observacao: envia o arquivo app-release.apk para o celular.
app.get('/download', (request, response, next) => {
  response.download(apkPath, 'leitor-qr-talmax.apk', (error) => {
    if (error && !response.headersSent) {
      next(error);
    }
  });
});

// GET /health
// Observacao: testa ao mesmo tempo se a API e o MySQL estao funcionando.
// Se estiver tudo certo, responde { "ok": true }.
app.get('/health', async (request, response, next) => {
  try {
    await pool.query('SELECT 1');
    response.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

// Todas as rotas criadas em routes/scans.js recebem o prefixo /scans.
app.use('/scans', scansRouter);

// Tratador central de erros.
// Observacao: registra o erro completo na janela da API, mas envia ao cliente
// apenas uma mensagem generica para nao expor usuario, senha ou detalhes do banco.
app.use((error, request, response, next) => {
  console.error(error);
  response.status(500).json({ error: 'Erro interno da API' });
});
