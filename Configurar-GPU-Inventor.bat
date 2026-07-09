@echo off
REM Executa o script Configurar-GPU-Inventor.ps1 com privilegios de administrador

REM Verifica se ja esta rodando como administrador
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Solicitando privilegios de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Executando Configurar-GPU-Inventor.ps1 ...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Configurar-GPU-Inventor.ps1"

echo.
echo Concluido.
pause
