@echo off
rem Le configuracao.env e incorpora o endereco da API no APK.
rem Comunica-se com: configuracao.env, Flutter e android/app.
setlocal
title Gerar APK Leitor QR Code
cd /d "%~dp0"

if not exist "configuracao.env" (
  echo ERRO: arquivo configuracao.env nao encontrado.
  pause
  exit /b 1
)

rem Cada linha CHAVE=VALOR vira uma variavel usada por este script.
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("configuracao.env") do set "%%A=%%B"

if not defined API_HOST (
  echo ERRO: configure API_HOST em configuracao.env.
  pause
  exit /b 1
)

if not defined PORT set "PORT=3000"
set "API_BASE_URL=http://%API_HOST%:%PORT%"

echo Gerando APK conectado a %API_BASE_URL%...
call flutter pub get
if errorlevel 1 goto erro

rem dart-define entrega a URL para remote_scan_service.dart durante a compilacao.
call flutter build apk --release --dart-define=API_BASE_URL=%API_BASE_URL%
if errorlevel 1 goto erro

echo.
echo APK gerado em:
echo build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0

:erro
echo.
echo Nao foi possivel gerar o APK.
pause
exit /b 1
