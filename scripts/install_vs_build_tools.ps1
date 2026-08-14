# Instala Visual Studio 2022 Build Tools con C++ para poder compilar Flutter Windows
# Ejecutar en PowerShell como Administrador

$ErrorActionPreference = "Stop"

Write-Host "=== Instalación de Visual Studio 2022 Build Tools ===" -ForegroundColor Cyan

# Detectar winget
$winget = Get-Command winget -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Error "winget no está disponible. Instala App Installer desde Microsoft Store o usa el instalador manual."
    exit 1
}

Write-Host "Instalando Visual Studio 2022 Build Tools con workload C++..." -ForegroundColor Yellow
Write-Host "Este proceso puede tardar varios minutos y requiere conexión a internet." -ForegroundColor Yellow

& winget install Microsoft.VisualStudio.2022.BuildTools `
    --silent `
    --accept-package-agreements `
    --accept-source-agreements `
    --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --includeRecommended"

if ($LASTEXITCODE -ne 0) {
    Write-Error "La instalación falló. Código de salida: $LASTEXITCODE"
    exit 1
}

Write-Host ""
Write-Host "Instalación completada. Reinicia el ordenador y luego ejecuta:" -ForegroundColor Green
Write-Host "  flutter build windows --release" -ForegroundColor Green
