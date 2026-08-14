# Build all RoomMate Match release artifacts
# Run this from the repository root in PowerShell

$ErrorActionPreference = "Stop"

Write-Host "=== RoomMate Match - Build All ===" -ForegroundColor Cyan

# Backend
Write-Host ""
Write-Host "[1/6] Building backend..." -ForegroundColor Cyan
Set-Location -Path (Join-Path $PSScriptRoot ".." "backend")
npm install
npm run build

# Flutter clean
Write-Host ""
Write-Host "[2/6] Flutter clean..." -ForegroundColor Cyan
Set-Location -Path (Join-Path $PSScriptRoot ".." "mobile")
flutter clean

# Android AAB
Write-Host ""
Write-Host "[3/6] Building Android App Bundle..." -ForegroundColor Cyan
flutter build appbundle --release

# Android APK
Write-Host ""
Write-Host "[4/6] Building Android APK..." -ForegroundColor Cyan
flutter build apk --release

# Web
Write-Host ""
Write-Host "[5/6] Building Web..." -ForegroundColor Cyan
flutter build web --release

# Windows
Write-Host ""
Write-Host "[6/6] Building Windows..." -ForegroundColor Cyan
flutter build windows --release

Write-Host ""
Write-Host "=== Build complete ===" -ForegroundColor Green
Write-Host "Artifacts:"
Write-Host "  - mobile/build/app/outputs/bundle/release/app-release.aab"
Write-Host "  - mobile/build/app/outputs/flutter-apk/app-release.apk"
Write-Host "  - mobile/build/web/"
Write-Host "  - mobile/build/windows/x64/runner/Release/"
