// Entrada da API Node.js.
// Observacao: inicializa o banco e sobe o servidor HTTP usado pelo Railway.
import { app } from './app.js';
import { port } from './config.js';
import { initDatabase } from './database.js';

await initDatabase();

app.listen(port, () => {
  console.log(`API rodando na porta ${port}`);
});
