// Configuracao central da API.
// Observacao: le IP, porta e dados do MySQL no arquivo configuracao.env.
// Comunica-se com: configuracao.env, database.js e server.js.
import dotenv from 'dotenv';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Descobre o caminho da raiz sem depender da pasta usada para iniciar o Node.
const currentDirectory = dirname(fileURLToPath(import.meta.url));
const configurationPath = resolve(
  currentDirectory,
  '..',
  '..',
  'suporte',
  'config',
  'configuracao.env',
);
// Carrega cada linha CHAVE=VALOR em process.env.
const configuration = dotenv.config({ path: configurationPath });

if (configuration.error) {
  throw new Error(
    `Arquivo de configuração não encontrado: ${configurationPath}`,
  );
}

export const port = Number(process.env.PORT || 3000);

export function mysqlPoolConfig() {
  // Reune os dados que mysql2 precisa para criar o pool de conexoes.
  const database = process.env.MYSQL_DATABASE;

  if (!database) {
    throw new Error('Configure MYSQL_DATABASE no arquivo configuracao.env.');
  }

  return {
    host: process.env.MYSQL_HOST || '127.0.0.1',
    port: Number(process.env.MYSQL_PORT || 3306),
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || '',
    database,
    // Aguarda uma conexao livre quando todas estiverem ocupadas.
    waitForConnections: true,
    // Permite no maximo dez conexoes simultaneas com o MySQL.
    connectionLimit: 10,
  };
}
