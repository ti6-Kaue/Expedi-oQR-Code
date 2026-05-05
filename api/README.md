# API QR/DataMatrix

API simples para salvar leituras do app Flutter em MySQL no Railway.

## Estrutura

```text
src/
  app.js              Express app e middlewares
  config.js           Leitura de porta e variaveis do MySQL
  database.js         Pool MySQL e criacao da tabela
  server.js           Entrada do servidor
  routes/scans.js     Endpoints de leituras
```

Arquivos `package.json` e `package-lock.json` nao recebem comentarios dentro do codigo porque JSON nao aceita comentarios.

## Variaveis no Railway

Use uma destas opcoes:

```text
MYSQL_URL=mysql://usuario:senha@host:3306/banco
```

Ou as variaveis separadas que o Railway cria para MySQL:

```text
MYSQLHOST
MYSQLPORT
MYSQLUSER
MYSQLPASSWORD
MYSQLDATABASE
```

## Endpoints

```text
GET /health
GET /scans
POST /scans
```

Body do `POST /scans`:

```json
{
  "value": "01079087187518382407322\u001d10L2250917002-450-A\u001d921\u001d1125091793297\u001d94293\u001d95P",
  "format": "QR Code",
  "gtin": "07908718751838",
  "produto": "7322",
  "lote": "L2250917002-450-A",
  "quantidade": "1",
  "data_fab": "250917",
  "caixa": "297",
  "qtd_etiqueta": "293",
  "tipo": "P"
}
```

Se o app enviar apenas `value` e `format`, a API tambem tenta separar os campos
GS1 antes de gravar no MySQL.

## Flutter

Depois de subir a API no Railway, gere o APK com a URL publica:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://sua-api.up.railway.app
```
