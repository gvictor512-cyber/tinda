# Setup script for Android release keystore
# Run this from the repository root in PowerShell

$androidDir = Join-Path $PSScriptRoot ".." "mobile" "android"
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$keyPropertiesPath = Join-Path $androidDir "key.properties"

Write-Host "=== RoomMate Match - Android Keystore Setup ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Error "keytool not found. Please install Java JDK and add it to PATH."
    exit 1
}

$password = Read-Host "Enter a secure password for the keystore" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

Write-Host "Generating keystore at $keystorePath ..."

& keytool -genkey `
    -v `
    -keystore "$keystorePath" `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass "$plainPassword" `
    -keypass "$plainPassword" `
    -dname "CN=RoomMate Match, O=RoomMate Match, C=ES"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Keystore generation failed."
    exit 1
}

$absoluteKeystorePath = (Resolve-Path $keystorePath).Path

$keyProperties = @"
storePassword=$plainPassword
keyPassword=$plainPassword
keyAlias=upload
storeFile=$absoluteKeystorePath
"@

Set-Content -Path $keyPropertiesPath -Value $keyProperties

Write-Host ""
Write-Host "Keystore created: $keystorePath" -ForegroundColor Green
Write-Host "key.properties written: $keyPropertiesPath" -ForegroundColor Green
Write-Host ""
Write-Warning "KEEP THIS FILE SAFE. If you lose the keystore, you cannot update the app on Google Play."
