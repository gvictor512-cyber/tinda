# Start local backend dependencies for development
# Requires Docker Desktop installed and running

$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot ".."

Write-Host "=== RoomMate Match - Backend Setup ===" -ForegroundColor Cyan

# 1. Start PostgreSQL with Docker Compose
Write-Host ""
Write-Host "[1/2] Starting PostgreSQL with Docker Compose..." -ForegroundColor Cyan
Set-Location -Path $root
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker Compose failed. Make sure Docker Desktop is running."
    exit 1
}

# 2. Ensure .env exists
$envExample = Join-Path $root "backend" ".env.example"
$envFile = Join-Path $root "backend" ".env"

if (-not (Test-Path $envFile)) {
    Write-Host ""
    Write-Host "[2/2] Creating backend/.env from example..." -ForegroundColor Cyan
    Copy-Item -Path $envExample -Destination $envFile
    Write-Warning "Please review and update backend/.env with your real values."
} else {
    Write-Host ""
    Write-Host "[2/2] backend/.env already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "PostgreSQL should now be available at localhost:5432" -ForegroundColor Green
Write-Host "Database: roommatematch | User: postgres | Password: postgres" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Update backend/.env with real Firebase, Stripe and DB values."
Write-Host "  2. cd backend"
Write-Host "  3. npm install"
Write-Host "  4. npm run start:dev"
