@echo off
rem Inicia a API local com os dados definidos no arquivo central.
rem Comunica-se com: ../configuracao.env e src/server.js.
setlocal
title API Leitor QR Code
cd /d "%~dp0"

if not exist "..\configuracao.env" (
  echo ERRO: arquivo configuracao.env nao encontrado.
  pause
  exit /b 1
)

rem Carrega IP, porta e dados do MySQL como variaveis de ambiente.
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("..\configuracao.env") do set "%%A=%%B"
if not defined PORT set "PORT=3000"

echo Iniciando API em http://%API_HOST%:%PORT%
echo Mantenha esta janela aberta durante o uso dos leitores.
echo.
node src\server.js
pause
