#Requires -Version 5.1
# Script para generar builds release de RoomMate Match.
# Uso:
#   .\build_release.ps1 -Target apk
#   .\build_release.ps1 -Target aab
#   .\build_release.ps1 -Target all   (por defecto)

param(
    [ValidateSet('apk', 'aab', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'

Push-Location $PSScriptRoot
try {
    if ($Target -eq 'apk' -or $Target -eq 'all') {
        Write-Host "Building release APK..." -ForegroundColor Cyan
        flutter build apk --release
        if ($LASTEXITCODE -ne 0) { throw "APK build failed" }
    }

    if ($Target -eq 'aab' -or $Target -eq 'all') {
        Write-Host "Building release AAB via Gradle..." -ForegroundColor Cyan
        Push-Location android
        .\gradlew.bat :app:bundleRelease
        if ($LASTEXITCODE -ne 0) { throw "AAB build failed" }
        Pop-Location
    }

    Write-Host "Done. Generated artifacts:" -ForegroundColor Green
    $apk = 'build/app/outputs/flutter-apk/app-release.apk'
    $aab = 'build/app/outputs/bundle/release/app-release.aab'
    if (Test-Path $apk) { Write-Host "  APK: $apk" -ForegroundColor Green }
    if (Test-Path $aab) { Write-Host "  AAB: $aab" -ForegroundColor Green }
} finally {
    Pop-Location
}
