@echo off
rem Le a configuracao central e incorpora o endereco da API no APK.
setlocal
title Gerar APK Leitor QR Code
for %%I in ("%~dp0..\..") do set "PROJECT_ROOT=%%~fI"
set "CONFIG_FILE=%PROJECT_ROOT%\suporte\config\configuracao.env"
cd /d "%PROJECT_ROOT%"

if not exist "%CONFIG_FILE%" (
  echo ERRO: arquivo de configuracao nao encontrado.
  pause
  exit /b 1
)

rem Cada linha CHAVE=VALOR vira uma variavel usada por este script.
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do set "%%A=%%B"

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
