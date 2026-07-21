# Documentacao do projeto Leitor QR Code

Este arquivo mostra onde cada funcao esta e como os arquivos se comunicam.
Arquivos gerados automaticamente dentro de `build/`, `.dart_tool/` e
`api/node_modules/` nao devem ser alterados manualmente.

## Fluxo principal

```text
lib/main.dart
  -> lib/src/app/qr_datamatrix_app.dart
      -> lib/src/features/scanner/scanner_home_page.dart
          -> mobile_scanner abre a camera
          -> parsed_gs1_code.dart interpreta o codigo
          -> local_scan_storage.dart salva no aparelho
          -> scanner_sound_feedback.dart solicita o som ao Android
          -> remote_scan_service.dart envia POST /scans
              -> api/src/app.js
                  -> api/src/routes/scans.js
                      -> api/src/database.js
                          -> MySQL / tabela scans
```

## Aplicativo Flutter (`lib`)

| Arquivo | Responsabilidade | Comunica-se com |
| --- | --- | --- |
| `lib/main.dart` | Inicia o Flutter. | `qr_datamatrix_app.dart` |
| `lib/src/app/qr_datamatrix_app.dart` | Cria tema e tela inicial. | `app_colors.dart`, `scanner_home_page.dart` |
| `lib/src/app/app_colors.dart` | Centraliza as cores. | Todos os componentes visuais |
| `lib/src/features/scanner/scanner_home_page.dart` | Controla camera, leitura, tela, historico e salvamento. | Models, services e utils |
| `lib/src/models/parsed_gs1_code.dart` | Interpreta campos GS1. | Tela e `saved_scan.dart` |
| `lib/src/models/saved_scan.dart` | Representa uma leitura. | Armazenamento local e API |
| `lib/src/services/local_scan_storage.dart` | Salva historico e som escolhido no aparelho. | `shared_preferences`, `saved_scan.dart` |
| `lib/src/services/remote_scan_service.dart` | Envia a leitura para `POST /scans`. | API Node.js |
| `lib/src/services/scanner_sound_feedback.dart` | Solicita beep, confirmacao, aviso ou silencio. | `MainActivity.kt` |
| `lib/src/utils/barcode_format_label.dart` | Formata tipo do codigo e data. | Tela principal |

## API local (`api`)

| Arquivo | Responsabilidade | Comunica-se com |
| --- | --- | --- |
| `api/src/server.js` | Inicia a API na porta configurada. | `config.js`, `database.js`, `app.js` |
| `api/src/config.js` | Le `configuracao.env`. | `database.js`, `server.js` |
| `api/src/database.js` | Cria a conexao e a tabela `scans`. | MySQL |
| `api/src/app.js` | Registra rotas, JSON, CORS e erros. | `routes/scans.js`, `database.js` |
| `api/src/routes/scans.js` | Lista e grava leituras. | `database.js` |

## Rotas HTTP

| Metodo | Endereco | Funcao |
| --- | --- | --- |
| GET | `/` | Pagina para baixar o APK. |
| GET | `/download` | Entrega o arquivo APK. |
| GET | `/health` | Testa API e MySQL. |
| GET | `/scans` | Lista as ultimas 100 leituras. |
| POST | `/scans` | Grava uma leitura. |

## Android (`android/app`)

| Arquivo | Responsabilidade |
| --- | --- |
| `android/app/build.gradle.kts` | Configura a compilacao do APK. |
| `android/app/src/main/AndroidManifest.xml` | Declara camera, internet e Activity. |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Recebe do Flutter a solicitacao para tocar sons. |
| `android/app/src/main/res/` | Guarda icones, estilos e tela de abertura. |

## Configuracao e comandos

- `configuracao.env`: unico local com IP, porta e dados do MySQL.
- `api/iniciar_api.cmd`: le a configuracao e inicia a API.
- `gerar_apk.cmd`: le o mesmo IP/porta e gera o APK.
- `pubspec.yaml`: dependencias e imagens usadas pelo Flutter.
- `api/package.json`: dependencias da API Node.js.

## Caminho de uma leitura

1. `MobileScanner` detecta o QR Code ou Data Matrix.
2. `_handleDetect` guarda a ultima leitura e toca o som escolhido.
3. `ParsedGs1Code` separa GTIN, produto, lote e outros campos.
4. Ao tocar em **Salvar leitura**, `LocalScanStorage` salva no aparelho.
5. `RemoteScanService` converte a leitura em JSON e envia para `/scans`.
6. `scans.js` valida os campos e executa o `INSERT` no MySQL.
7. A API responde HTTP 201 e o aplicativo informa que salvou no banco.

## Onde alterar cada coisa

- Cores: `lib/src/app/app_colors.dart`.
- Tela e botoes: `lib/src/features/scanner/scanner_home_page.dart`.
- Campos GS1: `lib/src/models/parsed_gs1_code.dart`.
- Sons: `lib/src/services/scanner_sound_feedback.dart` e `MainActivity.kt`.
- IP, porta e banco: `configuracao.env`.
- Colunas da tabela: `api/src/database.js` e `api/src/routes/scans.js`.
- Nome e versao do app: `pubspec.yaml` e `android/app/build.gradle.kts`.
