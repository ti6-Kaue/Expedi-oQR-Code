@echo off
setlocal

cd /d "%~dp0.."

if not exist "C:\flutter\bin\flutter.bat" (
  echo Flutter nao encontrado em C:\flutter\bin\flutter.bat
  pause
  exit /b 1
)

echo Atualizando logo...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0atualizar_logo.ps1"
if errorlevel 1 (
  echo.
  echo Falha ao atualizar a logo.
  pause
  exit /b 1
)

echo Limpando cache do Flutter...
"C:\flutter\bin\flutter.bat" clean
if errorlevel 1 (
  pause
  exit /b 1
)

echo Baixando dependencias...
"C:\flutter\bin\flutter.bat" pub get
if errorlevel 1 (
  pause
  exit /b 1
)

echo Gerando APK com a API do Railway...
"C:\flutter\bin\flutter.bat" build apk --debug --dart-define=API_BASE_URL=https://talmaxqr-code-production.up.railway.app
if errorlevel 1 (
  echo.
  echo Falha ao gerar o APK.
  pause
  exit /b 1
)

if not exist "dist" mkdir "dist"
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "dist\app-debug.apk"

echo.
echo APK gerado em:
echo %cd%\dist\app-debug.apk
pause
