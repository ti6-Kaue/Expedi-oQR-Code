// Conexao com o MySQL e criacao da tabela.
// Observacao: a tabela scans e criada automaticamente se ainda nao existir.
import mysql from 'mysql2/promise';

import { mysqlPoolConfig } from './config.js';

export const pool = mysql.createPool(mysqlPoolConfig());

export async function initDatabase() {
  await pool.execute(`
    CREATE TABLE IF NOT EXISTS scans (
      id INT AUTO_INCREMENT PRIMARY KEY,
      value TEXT NOT NULL,
      format VARCHAR(50) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}
