# Leitor QR/DataMatrix

App Flutter Android para ler QR Code/Data Matrix, salvar historico local e enviar leituras para uma API Node.js com MySQL no Railway.

## Estrutura

```text
android/                  Projeto Android do Flutter
lib/
  main.dart               Entrada do app
  src/app/                Tema e MaterialApp
  src/features/scanner/   Tela e widgets do scanner
  src/models/             Modelos de dados
  src/services/           Storage local, API e som nativo
  src/utils/              Formatadores e helpers
api/
  src/                    API Express para MySQL Railway
```

## Guia rapido dos arquivos

```text
lib/main.dart
  Entrada do app Flutter.

lib/src/app/app_colors.dart
  Paleta de cores do frontend.

lib/src/app/qr_datamatrix_app.dart
  Tema global, MaterialApp e tela inicial.

lib/src/features/scanner/scanner_home_page.dart
  Tela principal: camera, leitura, botao salvar e historico.

lib/src/services/local_scan_storage.dart
  Salva historico no celular.

lib/src/services/remote_scan_service.dart
  Envia leitura para a API Railway.

lib/src/services/scanner_sound_feedback.dart
  Toca som de leitura e erro.

api/src/
  Backend Node.js que grava no MySQL.

android/app/src/main/AndroidManifest.xml
  Permissoes Android, como camera e internet.

android/app/src/main/kotlin/.../MainActivity.kt
  Codigo Android nativo usado para tocar beep.
```

Arquivos como `pubspec.lock`, `api/package-lock.json`, `.metadata`, `build/` e `.dart_tool/` sao gerados por ferramentas. Em geral, nao edite manualmente.

## Rodar no celular

```powershell
flutter run -d RXCW80A8X2L --dart-define=API_BASE_URL=https://talmaxqr-code-production.up.railway.app
```

## Gerar APK conectado na API

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://talmaxqr-code-production.up.railway.app
```

O APK fica em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## API Railway

No Railway, o servico da API deve usar:

```text
Root Directory: api
Start Command: npm start
```

Variavel obrigatoria:

```text
MYSQL_URL
```

Teste:

```text
https://talmaxqr-code-production.up.railway.app/health
```
