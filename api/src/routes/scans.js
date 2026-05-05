// Rotas das leituras salvas.
// Observacao: GET lista leituras e POST grava uma nova leitura no MySQL.
import { Router } from 'express';

import { pool } from '../database.js';

export const scansRouter = Router();

scansRouter.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, value, format, gtin, produto, lote, quantidade,
              data_fab, caixa, qtd_etiqueta, tipo, created_at
       FROM scans
       ORDER BY id DESC
       LIMIT 100`,
    );
    res.json(rows);
  } catch (error) {
    next(error);
  }
});

scansRouter.post('/', async (req, res, next) => {
  try {
    const value = String(req.body?.value || '').trim();
    const format = String(req.body?.format || '').trim();
    const parsedFields = parseGs1Fields(value);
    const fields = {
      gtin: optionalText(req.body?.gtin) ?? parsedFields.gtin ?? null,
      produto: optionalText(req.body?.produto) ?? parsedFields.produto ?? null,
      lote: optionalText(req.body?.lote) ?? parsedFields.lote ?? null,
      quantidade:
        optionalText(req.body?.quantidade) ?? parsedFields.quantidade ?? null,
      data_fab:
        optionalText(req.body?.data_fab) ?? parsedFields.data_fab ?? null,
      caixa: optionalText(req.body?.caixa) ?? parsedFields.caixa ?? null,
      qtd_etiqueta:
        optionalText(req.body?.qtd_etiqueta) ??
        parsedFields.qtd_etiqueta ??
        null,
      tipo: optionalText(req.body?.tipo) ?? parsedFields.tipo ?? null,
    };

    if (!value || !format) {
      return res.status(400).json({
        error: 'value e format sao obrigatorios',
      });
    }

    const [result] = await pool.execute(
      `INSERT INTO scans (
        value, format, gtin, produto, lote, quantidade,
        data_fab, caixa, qtd_etiqueta, tipo
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        value,
        format,
        fields.gtin,
        fields.produto,
        fields.lote,
        fields.quantidade,
        fields.data_fab,
        fields.caixa,
        fields.qtd_etiqueta,
        fields.tipo,
      ],
    );

    const [rows] = await pool.execute(
      `SELECT id, value, format, gtin, produto, lote, quantidade,
              data_fab, caixa, qtd_etiqueta, tipo, created_at
       FROM scans
       WHERE id = ?`,
      [result.insertId],
    );

    return res.status(201).json(rows[0]);
  } catch (error) {
    next(error);
  }
});

const groupSeparator = String.fromCharCode(29);

const gs1Definitions = [
  { ai: '240', key: 'produto', maxLength: 30 },
  { ai: '01', key: 'gtin', fixedLength: 14 },
  { ai: '10', key: 'lote', maxLength: 20 },
  { ai: '11', key: 'data_fab', fixedLength: 6 },
  { ai: '92', key: 'quantidade', maxLength: 90 },
  { ai: '93', key: 'caixa', maxLength: 90 },
  { ai: '94', key: 'qtd_etiqueta', maxLength: 90 },
  { ai: '95', key: 'tipo', maxLength: 90 },
];

function optionalText(value) {
  const text = String(value ?? '').trim();
  return text || null;
}

function parseGs1Fields(rawValue) {
  const fields = {};
  const value = normalizeGs1Value(rawValue);
  let index = 0;

  while (index < value.length) {
    if (value[index] === groupSeparator) {
      index += 1;
      continue;
    }

    const definition = gs1Definitions.find((item) =>
      value.startsWith(item.ai, index),
    );

    if (!definition) {
      return fields;
    }

    index += definition.ai.length;

    const fieldValue = definition.fixedLength
      ? readFixedValue(value, index, definition.fixedLength)
      : readVariableValue(value, index, definition.maxLength);

    if (!fieldValue) {
      return fields;
    }

    if (fieldValue.value.trim()) {
      fields[definition.key] = fieldValue.value.trim();
    }

    index = fieldValue.nextIndex;
  }

  return fields;
}

function readFixedValue(value, index, length) {
  const end = index + length;

  if (end > value.length) {
    return null;
  }

  return {
    value: value.slice(index, end),
    nextIndex: end,
  };
}

function readVariableValue(value, index, maxLength) {
  const separatorIndex = value.indexOf(groupSeparator, index);
  const end = separatorIndex === -1 ? value.length : separatorIndex;
  const fullValue = value.slice(index, end);

  return {
    value: fullValue.length > maxLength ? fullValue.slice(0, maxLength) : fullValue,
    nextIndex: separatorIndex === -1 ? value.length : separatorIndex + 1,
  };
}

function normalizeGs1Value(rawValue) {
  const value = String(rawValue || '').trim();
  const withoutSymbologyIdentifier =
    value.startsWith(']') && value.length > 3 ? value.slice(3) : value;

  return withoutSymbologyIdentifier
    .replaceAll('\\u001d', groupSeparator)
    .replaceAll('\\u001D', groupSeparator)
    .replaceAll('\\x1d', groupSeparator)
    .replaceAll('\\x1D', groupSeparator);
}
