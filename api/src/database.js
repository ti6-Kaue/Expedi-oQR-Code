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
      gtin VARCHAR(14),
      produto VARCHAR(30),
      lote VARCHAR(20),
      quantidade VARCHAR(30),
      data_fab CHAR(6),
      caixa VARCHAR(30),
      qtd_etiqueta VARCHAR(30),
      tipo VARCHAR(10),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await ensureScanColumns();
}

const scanColumns = [
  { name: 'gtin', definition: 'VARCHAR(14)' },
  { name: 'produto', definition: 'VARCHAR(30)' },
  { name: 'lote', definition: 'VARCHAR(20)' },
  { name: 'quantidade', definition: 'VARCHAR(30)' },
  { name: 'data_fab', definition: 'CHAR(6)' },
  { name: 'caixa', definition: 'VARCHAR(30)' },
  { name: 'qtd_etiqueta', definition: 'VARCHAR(30)' },
  { name: 'tipo', definition: 'VARCHAR(10)' },
];

async function ensureScanColumns() {
  const [columns] = await pool.execute(`
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'scans'
  `);
  const existingColumns = new Set(columns.map((column) => column.COLUMN_NAME));

  for (const column of scanColumns) {
    if (!existingColumns.has(column.name)) {
      await pool.execute(
        `ALTER TABLE scans ADD COLUMN ${column.name} ${column.definition}`,
      );
    }
  }
}
