// Conexao e estrutura do banco MySQL.
// Comunica-se com: config.js, app.js, routes/scans.js e MySQL.
import mysql from 'mysql2/promise';

import { mysqlPoolConfig } from './config.js';

// O pool reaproveita conexoes em vez de abrir uma nova em cada requisicao.
export const pool = mysql.createPool(mysqlPoolConfig());

export async function initDatabase() {
  // Cria a tabela apenas quando ela ainda nao existe.
  // Nenhum registro existente e apagado por este comando.
  await pool.execute(`
    CREATE TABLE IF NOT EXISTS scans (
      scan_id INT AUTO_INCREMENT PRIMARY KEY,
      scan_value TEXT NOT NULL,
      scan_format VARCHAR(50) NOT NULL,
      scan_gtin VARCHAR(14),
      scan_produto VARCHAR(30),
      scan_lote VARCHAR(20),
      scan_quantidade VARCHAR(30),
      scan_data_fab CHAR(6),
      scan_caixa VARCHAR(30),
      scan_qtd_etiqueta VARCHAR(30),
      scan_tipo VARCHAR(10),
      scan_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}
