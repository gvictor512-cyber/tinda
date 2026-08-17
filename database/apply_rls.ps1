# Aplica database/rls.sql a PostgreSQL sustituyendo la contraseña del rol app_user
# Uso: .\apply_rls.ps1 -Db "roommatematch" -User "postgres" -Password "postgres" -AppPassword "app_user_password"
param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Db = "roommatematch",
    [string]$User = "postgres",
    [string]$Password = "",
    [string]$AppPassword = "app_user_password"
)

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Error "psql no esta en el PATH. Instala PostgreSQL client tools."
    exit 1
}

$rlsSql = Get-Content -Path "$PSScriptRoot\rls.sql" -Raw
$rlsSql = $rlsSql -replace "'CHANGE_ME_IN_ENV'", "'$AppPassword'"

$env:PGPASSWORD = $Password
$rlsSql | psql -h $Host -p $Port -U $User -d $Db -v ON_ERROR_STOP=1
