// Rotas responsaveis pelas leituras do scanner.
// Comunica-se com: app.js, database.js, MySQL e remote_scan_service.dart.
// Router cria um grupo de enderecos relacionados as leituras do scanner.
import { Router } from 'express';

// pool e a conexao compartilhada com o banco MySQL.
import { pool } from '../database.js';

export const scansRouter = Router();

// GET /scans
// Observacao: lista as 100 leituras mais recentes para consulta.
// Os nomes "AS id", "AS value" etc. deixam a resposta mais simples,
// mesmo que as colunas no MySQL comecem com o prefixo "scan_".
scansRouter.get('/', async (request, response, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT scan_id AS id, scan_value AS value,
              scan_format AS format, scan_gtin AS gtin,
              scan_produto AS produto, scan_lote AS lote,
              scan_quantidade AS quantidade, scan_data_fab AS data_fab,
              scan_caixa AS caixa, scan_qtd_etiqueta AS qtd_etiqueta,
              scan_tipo AS tipo, scan_created_at AS created_at
        FROM scans ORDER BY scan_id DESC LIMIT 100`,
    );
    // Retorna as leituras no formato JSON para quem chamou a API.
    response.json(rows);
  } catch (error) {
    // Envia erros do MySQL para o tratador central definido em app.js.
    next(error);
  }
});

// POST /scans
// Observacao: recebe uma leitura enviada pelo aplicativo e salva no MySQL.
scansRouter.post('/', async (request, response, next) => {
  try {
    // value e o conteudo lido; format informa se e QR Code ou Data Matrix.
    const value = textOrNull(request.body?.value);
    const format = textOrNull(request.body?.format);

    // Sem esses dois campos nao e possivel identificar a leitura.
    if (!value || !format) {
      return response.status(400).json({
        error: 'value e format sao obrigatorios',
      });
    }

    // Estes campos sao opcionais e representam os dados GS1 interpretados
    // pelo aplicativo. Quando um valor nao existe, sera gravado como NULL.
    const fields = [
      'gtin',
      'produto',
      'lote',
      'quantidade',
      'data_fab',
      'caixa',
      'qtd_etiqueta',
      'tipo',
    ].map((field) => textOrNull(request.body?.[field]));

    // Os sinais ? evitam montar SQL com texto recebido do usuario.
    // O mysql2 substitui cada ? pelo valor correspondente com seguranca.
    const [result] = await pool.execute(
      `INSERT INTO scans (
        scan_value, scan_format, scan_gtin, scan_produto, scan_lote,
        scan_quantidade, scan_data_fab, scan_caixa,
        scan_qtd_etiqueta, scan_tipo
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [value, format, ...fields],
    );

    // result.insertId e o scan_id criado automaticamente pelo MySQL.
    // Buscamos o registro para devolver ao aplicativo exatamente o que foi salvo.
    const [rows] = await pool.execute(
      `SELECT scan_id AS id, scan_value AS value,
              scan_format AS format, scan_gtin AS gtin,
              scan_produto AS produto, scan_lote AS lote,
              scan_quantidade AS quantidade, scan_data_fab AS data_fab,
              scan_caixa AS caixa, scan_qtd_etiqueta AS qtd_etiqueta,
              scan_tipo AS tipo, scan_created_at AS created_at
        FROM scans WHERE scan_id = ?`,
      [result.insertId],
    );

    // HTTP 201 significa que um novo registro foi criado com sucesso.
    return response.status(201).json(rows[0]);
  } catch (error) {
    // Qualquer erro de gravacao segue para o tratador central da API.
    next(error);
  }
});

// Converte qualquer valor para texto, remove espacos nas pontas
// e devolve null quando o campo esta vazio.
function textOrNull(value) {
  const text = String(value ?? '').trim();
  return text || null;
}
