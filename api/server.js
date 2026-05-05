import 'dotenv/config';

import cors from 'cors';
import express from 'express';
import mysql from 'mysql2/promise';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '64kb' }));

const pool = mysql.createPool(
  process.env.MYSQL_URL || process.env.DATABASE_URL
    ? {
        uri: process.env.MYSQL_URL || process.env.DATABASE_URL,
        waitForConnections: true,
        connectionLimit: 10,
      }
    : {
        host: process.env.MYSQLHOST || process.env.MYSQL_HOST || 'localhost',
        port: Number(process.env.MYSQLPORT || process.env.MYSQL_PORT || 3306),
        user: process.env.MYSQLUSER || process.env.MYSQL_USER || 'root',
        password: process.env.MYSQLPASSWORD || process.env.MYSQL_PASSWORD || '',
        database: process.env.MYSQLDATABASE || process.env.MYSQL_DATABASE,
        waitForConnections: true,
        connectionLimit: 10,
      },
);

async function initDatabase() {
  await pool.execute(`
    CREATE TABLE IF NOT EXISTS scans (
      id INT AUTO_INCREMENT PRIMARY KEY,
      value TEXT NOT NULL,
      format VARCHAR(50) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

app.get('/health', async (req, res, next) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

app.get('/scans', async (req, res, next) => {
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

app.post('/scans', async (req, res, next) => {
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

app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({ error: 'Erro interno da API' });
});

await initDatabase();

app.listen(port, () => {
  console.log(`API rodando na porta ${port}`);
});
