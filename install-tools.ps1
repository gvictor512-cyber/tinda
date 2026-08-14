# Script de Instalación Automática para RoomMate Match
# Este script descarga e instala todas las herramientas necesarias

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RoomMate Match - Instalación de Herramientas" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Crear directorio de descargas
$downloadsDir = "$env:USERPROFILE\Downloads\RoomMateMatch-Install"
New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
Write-Host "Directorio de descargas: $downloadsDir" -ForegroundColor Green
Write-Host ""

# Función para verificar si una herramienta está instalada
function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Verificar instalaciones actuales
Write-Host "Verificando instalaciones actuales..." -ForegroundColor Yellow
$nodeInstalled = Test-Command "node"
$npmInstalled = Test-Command "npm"
$flutterInstalled = Test-Command "flutter"
$psqlInstalled = Test-Command "psql"
$gitInstalled = Test-Command "git"

Write-Host "Node.js: $(if ($nodeInstalled) { 'INSTALADO' } else { 'NO INSTALADO' })" -ForegroundColor $(if ($nodeInstalled) { 'Green' } else { 'Red' })
Write-Host "npm: $(if ($npmInstalled) { 'INSTALADO' } else { 'NO INSTALADO' })" -ForegroundColor $(if ($npmInstalled) { 'Green' } else { 'Red' })
Write-Host "Flutter: $(if ($flutterInstalled) { 'INSTALADO' } else { 'NO INSTALADO' })" -ForegroundColor $(if ($flutterInstalled) { 'Green' } else { 'Red' })
Write-Host "PostgreSQL: $(if ($psqlInstalled) { 'INSTALADO' } else { 'NO INSTALADO' })" -ForegroundColor $(if ($psqlInstalled) { 'Green' } else { 'Red' })
Write-Host "Git: $(if ($gitInstalled) { 'INSTALADO' } else { 'NO INSTALADO' })" -ForegroundColor $(if ($gitInstalled) { 'Green' } else { 'Red' })
Write-Host ""

# 1. Node.js
if (-not $nodeInstalled) {
    Write-Host "1. Instalando Node.js..." -ForegroundColor Yellow
    $nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
    $nodeInstaller = "$downloadsDir\node-installer.msi"
    
    Write-Host "Descargando Node.js desde: $nodeUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
    
    Write-Host "Iniciando instalador de Node.js..." -ForegroundColor Green
    Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /quiet /norestart" -Wait
    
    Write-Host "Node.js instalado. Por favor reinicia tu terminal para usarlo." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "1. Node.js ya está instalado. Versión:" -ForegroundColor Green
    node --version
    Write-Host ""
}

# 2. Git
if (-not $gitInstalled) {
    Write-Host "2. Instalando Git..." -ForegroundColor Yellow
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.45.0.windows.1/Git-2.45.0-64-bit.exe"
    $gitInstaller = "$downloadsDir\git-installer.exe"
    
    Write-Host "Descargando Git desde: $gitUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
    
    Write-Host "Iniciando instalador de Git..." -ForegroundColor Green
    Start-Process $gitInstaller -ArgumentList "/VERYSILENT /NORESTART" -Wait
    
    Write-Host "Git instalado." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "2. Git ya está instalado. Versión:" -ForegroundColor Green
    git --version
    Write-Host ""
}

# 3. Flutter
if (-not $flutterInstalled) {
    Write-Host "3. Instalando Flutter..." -ForegroundColor Yellow
    $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip"
    $flutterZip = "$downloadsDir\flutter.zip"
    $flutterDir = "C:\flutter"
    
    Write-Host "Descargando Flutter desde: $flutterUrl" -ForegroundColor Gray
    Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    
    Write-Host "Extrayendo Flutter..." -ForegroundColor Green
    Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
    
    Write-Host "Añadiendo Flutter al PATH del sistema..." -ForegroundColor Green
    $env:Path += ";C:\flutter\bin"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
    
    Write-Host "Flutter instalado en C:\flutter" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "3. Flutter ya está instalado. Versión:" -ForegroundColor Green
    flutter --version
    Write-Host ""
}

# 4. PostgreSQL
if (-not $psqlInstalled) {
    Write-Host "4. Instalando PostgreSQL..." -ForegroundColor Yellow
    $pgUrl = "https://get.enterprisedb.com/postgresql/postgresql-15.6-1-windows-x64.exe"
    $pgInstaller = "$downloadsDir\postgresql-installer.exe"
    
    Write-Host "Descargando PostgreSQL desde: $pgUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $pgUrl -OutFile $pgInstaller -UseBasicParsing
    
    Write-Host "Iniciando instalador de PostgreSQL..." -ForegroundColor Green
    Write-Host "IMPORTANTE: Durante la instalación, establece la contraseña del usuario postgres" -ForegroundColor Yellow
    Write-Host "Recomendación: usa 'postgres' como contraseña para facilitar la configuración" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona cualquier tecla para continuar..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Start-Process $pgInstaller -Wait
    
    Write-Host "PostgreSQL instalado." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "4. PostgreSQL ya está instalado. Versión:" -ForegroundColor Green
    psql --version
    Write-Host ""
}

# 5. Android Studio (opcional)
Write-Host "5. Android Studio (opcional para emulador Android)..." -ForegroundColor Yellow
Write-Host "Para instalar Android Studio manualmente:" -ForegroundColor Gray
Write-Host "1. Ve a: https://developer.android.com/studio" -ForegroundColor Gray
Write-Host "2. Descarga e instala Android Studio" -ForegroundColor Gray
Write-Host "3. Configura el SDK de Android" -ForegroundColor Gray
Write-Host "4. Crea un emulador AVD" -ForegroundColor Gray
Write-Host ""

# Verificación final
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación Final" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Por favor reinicia tu terminal y ejecuta:" -ForegroundColor Yellow
Write-Host "node --version" -ForegroundColor White
Write-Host "npm --version" -ForegroundColor White
Write-Host "flutter --version" -ForegroundColor White
Write-Host "flutter doctor" -ForegroundColor White
Write-Host "psql --version" -ForegroundColor White
Write-Host "git --version" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalación completada" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Siguientes pasos:" -ForegroundColor Yellow
Write-Host "1. Reinicia tu terminal/computadora" -ForegroundColor White
Write-Host "2. Ejecuta este script de nuevo para verificar" -ForegroundColor White
Write-Host "3. Configura Firebase (https://console.firebase.google.com)" -ForegroundColor White
Write-Host "4. Ejecuta: cd backend && npm install" -ForegroundColor White
Write-Host "5. Ejecuta: cd mobile && flutter pub get" -ForegroundColor White
Write-Host ""
