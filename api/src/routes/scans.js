// Rotas das leituras salvas.
// Observacao: GET lista leituras e POST grava uma nova leitura no MySQL.
import { Router } from 'express';

import { pool } from '../database.js';

export const scansRouter = Router();

scansRouter.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, value, format, created_at
       FROM scans
       ORDER BY id DESC
       LIMIT 100`,
    );
    res.json(rows);
  } catch (error) {
    next(error);
  }
});

scansRouter.post('/', async (req, res, next) => {
  try {
    const value = String(req.body?.value || '').trim();
    const format = String(req.body?.format || '').trim();

    if (!value || !format) {
      return res.status(400).json({
        error: 'value e format sao obrigatorios',
      });
    }

    const [result] = await pool.execute(
      'INSERT INTO scans (value, format) VALUES (?, ?)',
      [value, format],
    );

    const [rows] = await pool.execute(
      `SELECT id, value, format, created_at
       FROM scans
       WHERE id = ?`,
      [result.insertId],
    );

    return res.status(201).json(rows[0]);
  } catch (error) {
    next(error);
  }
});
