// Configuracao da API.
// Observacao: le a porta e as variaveis de conexao MySQL vindas do Railway.
export const port = process.env.PORT || 3000;

export function mysqlPoolConfig() {
  const mysqlUrl =
    process.env.MYSQL_URL ||
    process.env.MYSQL_PUBLIC_URL ||
    process.env.MYSQL_PRIVATE_URL ||
    process.env.DATABASE_URL;

  const hasSeparateMysqlConfig =
    process.env.MYSQLHOST ||
    process.env.MYSQL_HOST ||
    process.env.MYSQLUSER ||
    process.env.MYSQL_USER;

  if (!mysqlUrl && !hasSeparateMysqlConfig) {
    throw new Error(
      'Configure MYSQL_URL, MYSQL_PUBLIC_URL ou as variaveis MYSQLHOST/MYSQLUSER/MYSQLPASSWORD/MYSQLDATABASE no servico da API.',
    );
  }

  if (mysqlUrl) {
    return {
      uri: mysqlUrl,
      waitForConnections: true,
      connectionLimit: 10,
    };
  }

  return {
    host: process.env.MYSQLHOST || process.env.MYSQL_HOST || 'localhost',
    port: Number(process.env.MYSQLPORT || process.env.MYSQL_PORT || 3306),
    user: process.env.MYSQLUSER || process.env.MYSQL_USER || 'root',
    password: process.env.MYSQLPASSWORD || process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQLDATABASE || process.env.MYSQL_DATABASE,
    waitForConnections: true,
    connectionLimit: 10,
  };
}
