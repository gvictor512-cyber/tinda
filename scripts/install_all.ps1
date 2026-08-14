# Instalador maestro de dependencias del sistema para RoomMate Match
# EJECUTAR EN POWERSHELL COMO ADMINISTRADOR

$ErrorActionPreference = "Stop"

Write-Host "=== Instalador de dependencias para RoomMate Match ===" -ForegroundColor Cyan
Write-Host "Este script instala software del sistema. Requiere permisos de administrador." -ForegroundColor Yellow

$scriptsDir = $PSScriptRoot

$components = @(
    @{ Name = "Visual Studio 2022 Build Tools (para Flutter Windows)"; Script = "install_vs_build_tools.ps1" },
    @{ Name = "Docker Desktop (para PostgreSQL local)"; Script = "install_docker_desktop.ps1" }
)

foreach ($c in $components) {
    $scriptPath = Join-Path $scriptsDir $c.Script
    Write-Host ""
    Write-Host "Instalando: $($c.Name)" -ForegroundColor Cyan
    if (Test-Path $scriptPath) {
        & powershell -ExecutionPolicy Bypass -File $scriptPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Fallo al instalar $($c.Name). Deteniendo."
            exit 1
        }
    } else {
        Write-Error "No se encuentra $scriptPath"
        exit 1
    }
}

Write-Host ""
Write-Host "=== Instalación completada ===" -ForegroundColor Green
Write-Host "Reinicia el ordenador y luego ejecuta:" -ForegroundColor Green
Write-Host "  docker compose up -d" -ForegroundColor Green
Write-Host "  cd backend; npm run start:dev" -ForegroundColor Green
Write-Host "  cd mobile; flutter build windows --release" -ForegroundColor Green
