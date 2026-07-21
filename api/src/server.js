// Ponto de entrada da API Node.js.
// Comunica-se com: config.js, database.js e app.js.
import { app } from './app.js';
import { port } from './config.js';
import { initDatabase } from './database.js';

// Garante que o MySQL responde e que a tabela existe antes de abrir a porta.
await initDatabase();

// 0.0.0.0 permite acesso por localhost e por outros aparelhos da rede.
app.listen(port, '0.0.0.0', () => {
  console.log(`API disponível na rede pela porta ${port}`);
});
