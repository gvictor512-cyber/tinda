# Subir RoomMate Match a GitHub con token seguro
# Ejecutar en PowerShell desde el directorio del proyecto

$ErrorActionPreference = "Stop"

$repo = "gvictor512-cyber/tinda"

Write-Host "Pega tu token de GitHub (no se mostrará en pantalla):" -ForegroundColor Cyan
$tokenSecure = Read-Host -AsSecureString

if ([string]::IsNullOrWhiteSpace($tokenSecure)) {
    Write-Error "No se introdujo ningún token."
    exit 1
}

$token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
)

try {
    Write-Host "Configurando remoto..." -ForegroundColor Yellow
    git remote set-url origin "https://$token@github.com/$repo.git"

    Write-Host "Subiendo a main..." -ForegroundColor Yellow
    git push -u origin main
}
finally {
    Write-Host "Limpiando token del remoto..." -ForegroundColor Yellow
    git remote set-url origin "https://github.com/$repo.git"
}

Write-Host "Hecho. Revisa en GitHub si el código está actualizado." -ForegroundColor Green
