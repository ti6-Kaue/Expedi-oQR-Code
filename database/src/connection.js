import mysql from 'mysql2/promise';

import { databaseConfig } from './config.js';

// Esta conexão será reutilizada quando a integração for implementada.
// Por enquanto, nenhum INSERT, UPDATE ou DELETE é executado.
export const databasePool = mysql.createPool({
  host: databaseConfig.host,
  port: databaseConfig.port,
  user: databaseConfig.user,
  password: databaseConfig.password,
  database: databaseConfig.defaultSchema,
  connectionLimit: databaseConfig.connectionLimit,
  waitForConnections: true,
  queueLimit: 0,
  charset: 'utf8mb4',
});
