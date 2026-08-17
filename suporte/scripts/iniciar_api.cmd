@echo off
rem Inicia a API local com os dados definidos no arquivo central.
setlocal
title API Leitor QR Code
for %%I in ("%~dp0..\..") do set "PROJECT_ROOT=%%~fI"
set "API_DIR=%PROJECT_ROOT%\api"
set "CONFIG_FILE=%PROJECT_ROOT%\suporte\config\configuracao.env"
cd /d "%API_DIR%"

if not exist "%CONFIG_FILE%" (
  echo ERRO: arquivo de configuracao nao encontrado.
  pause
  exit /b 1
)

rem Carrega IP, porta e dados do MySQL como variaveis de ambiente.
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do set "%%A=%%B"
if not defined PORT set "PORT=3000"

echo Iniciando API em http://%API_HOST%:%PORT%
echo Mantenha esta janela aberta durante o uso dos leitores.
echo.
node src\server.js
pause
