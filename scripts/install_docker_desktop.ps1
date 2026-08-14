# Instala Docker Desktop para poder levantar PostgreSQL local
# Ejecutar en PowerShell como Administrador

$ErrorActionPreference = "Stop"

Write-Host "=== Instalación de Docker Desktop ===" -ForegroundColor Cyan

$winget = Get-Command winget -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Error "winget no está disponible. Descarga Docker Desktop manualmente desde https://www.docker.com/products/docker-desktop/"
    exit 1
}

Write-Host "Instalando Docker Desktop con winget..." -ForegroundColor Yellow
& winget install Docker.DockerDesktop `
    --silent `
    --accept-package-agreements `
    --accept-source-agreements

if ($LASTEXITCODE -ne 0) {
    Write-Error "La instalación de Docker Desktop falló. Código: $LASTEXITCODE"
    exit 1
}

Write-Host ""
Write-Host "Docker Desktop instalado. Reinicia el ordenador, abre Docker y luego ejecuta:" -ForegroundColor Green
Write-Host "  docker compose up -d" -ForegroundColor Green
Write-Host "  npm run start:dev" -ForegroundColor Green
