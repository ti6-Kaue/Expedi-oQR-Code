// Configuracao do app Express.
// Observacao: registra middlewares, health check, rotas e tratamento de erro.
import cors from 'cors';
import express from 'express';

import { pool } from './database.js';
import { scansRouter } from './routes/scans.js';

export const app = express();

app.use(cors());
app.use(express.json({ limit: '64kb' }));

app.get('/health', async (req, res, next) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

app.use('/scans', scansRouter);

app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({ error: 'Erro interno da API' });
});
