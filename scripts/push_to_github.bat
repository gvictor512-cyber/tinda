@echo off
echo Ejecutando push a GitHub con politica de ejecucion omitida...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0push_to_github.ps1"
pause
