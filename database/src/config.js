import { config as carregarArquivoEnv } from 'dotenv';
import { fileURLToPath } from 'node:url';

// OBS: usa sempre o .env da pasta database, mesmo quando outro projeto
// (como o backend) importa esta configuração.
const caminhoDoEnv = fileURLToPath(new URL('../.env', import.meta.url));
carregarArquivoEnv({ path: caminhoDoEnv });

// Configuração única da conexão MySQL e das duas tabelas informadas.
export const databaseConfig = {
  host: requiredValue('DB_HOST'),
  port: positiveNumber('DB_PORT', 3306),
  user: requiredValue('DB_USER'),
  password: process.env.DB_PASSWORD || '',
  defaultSchema: identifier('DB_DEFAULT_SCHEMA', 'talmax'),
  connectionLimit: positiveNumber('DB_CONNECTION_LIMIT', 10),
  tables: {
    talmax: {
      schema: 'talmax',
      name: identifier('TABLE_TALMAX'),
    },
    portalPostal: {
      schema: 'portalpostal',
      name: identifier('TABLE_PORTALPOSTAL'),
    },
  },
};

function requiredValue(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Configuração obrigatória ausente no .env: ${name}`);
  }
  return value;
}

function positiveNumber(name, fallback) {
  const value = Number(process.env[name] || fallback);
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`Configuração numérica inválida no .env: ${name}`);
  }
  return value;
}

function identifier(name, fallback) {
  const value = (process.env[name] || fallback || '').trim();
  if (!/^[a-zA-Z0-9_]+$/.test(value)) {
    throw new Error(`${name} aceita somente letras, números e underscore.`);
  }
  return value;
}
