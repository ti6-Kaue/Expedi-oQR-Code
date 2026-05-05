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
  "value": "texto lido",
  "format": "QR Code"
}
```

## Flutter

Depois de subir a API no Railway, gere o APK com a URL publica:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://sua-api.up.railway.app
```
