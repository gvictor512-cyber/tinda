# Configure backend .env for local development with Docker PostgreSQL
# Run from repository root in PowerShell

$ErrorActionPreference = "Stop"
$rootDir = (Get-Item $PSScriptRoot).Parent.FullName
$backendDir = Join-Path $rootDir "backend"
$envExample = Join-Path $backendDir ".env.example"
$envFile = Join-Path $backendDir ".env"

# Copy example if .env doesn't exist
if (-not (Test-Path $envFile)) {
    if (-not (Test-Path $envExample)) {
        Write-Error "No existe backend/.env ni backend/.env.example"
        exit 1
    }
    Copy-Item -Path $envExample -Destination $envFile
    Write-Host "Creado $envFile desde .env.example" -ForegroundColor Green
}

# Read .env lines
$lines = @(Get-Content -Path $envFile)

# Helper to set or replace a variable
function Set-EnvValue($key, $value) {
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$key\s*=") {
            $lines[$i] = "$key=$value"
            $found = $true
            break
        }
    }
    if (-not $found) {
        $lines += "$key=$value"
    }
}

# Local PostgreSQL values
Set-EnvValue "DB_HOST" "localhost"
Set-EnvValue "DB_PORT" "5432"
Set-EnvValue "DB_USERNAME" "postgres"
Set-EnvValue "DB_PASSWORD" "postgres"
Set-EnvValue "DB_DATABASE" "roommatematch"
Set-EnvValue "PORT" "3000"
Set-EnvValue "NODE_ENV" "development"

# Write back (no output to avoid leaking secrets)
Set-Content -Path $envFile -Value $lines

Write-Host "backend/.env configurado para PostgreSQL local." -ForegroundColor Green
Write-Host "Recuerda rellenar STRIPE_SECRET_KEY, FIREBASE_PRIVATE_KEY, etc. con valores reales." -ForegroundColor Yellow
