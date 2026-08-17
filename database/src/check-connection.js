import { databaseConfig } from './config.js';
import { databasePool } from './connection.js';

// Confere a conexão e a existência das tabelas sem alterar registros.
try {
  await databasePool.query('SELECT 1');

  const configuredTables = [
    databaseConfig.tables.talmax,
    databaseConfig.tables.portalPostal,
  ];

  for (const table of configuredTables) {
    const [rows] = await databasePool.execute(
      `SELECT COUNT(*) AS encontrada
       FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?`,
      [table.schema, table.name],
    );

    const status = Number(rows[0].encontrada) === 1
        ? 'encontrada'
        : 'não encontrada';
    console.log(`${table.schema}.${table.name}: ${status}`);
  }

  console.log('Conexão MySQL configurada com sucesso.');
} catch (error) {
  console.error('Falha na conexão MySQL.');
  console.error(`Código: ${error.code || 'desconhecido'}`);
  console.error(`Mensagem: ${error.message}`);
  process.exitCode = 1;
} finally {
  await databasePool.end();
}
