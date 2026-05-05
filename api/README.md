# API QR/DataMatrix

API simples para salvar leituras do app Flutter em MySQL no Railway.

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
