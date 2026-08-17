# Conexão MySQL

Esta pasta contém somente a conexão com o banco. Não há API, servidor HTTP ou rotas.

## Arquivos

| Arquivo | Finalidade |
| --- | --- |
| `.env` | Host, porta, usuário, senha e tabelas |
| `src/config.js` | Lê e valida o `.env` |
| `src/connection.js` | Cria a conexão reutilizável com o MySQL |
| `src/check-connection.js` | Confere a conexão e as tabelas sem alterar dados |

## Regra do scanner

| Condição do código | Destino | Coluna preenchida |
| --- | --- | --- |
| Possui 13 ou 14 caracteres **e** termina com `BR` | `portalpostal.saida_objetos_temp` | `codigo` |
| Qualquer outro código numérico | `talmax.pedido_de_venda_saida_temp` | `pev_num` |

A regra do scanner fica no aplicativo Flutter em `lib/src/regras.dart`.

## Conferir a conexão

Dentro da pasta `database`, execute:

```powershell
npm run connection
```
