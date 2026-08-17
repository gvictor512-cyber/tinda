#!/bin/bash
# Aplica database/rls.sql a PostgreSQL sustituyendo la contraseña del rol app_user
# Uso: ./apply_rls.sh -d roomie -U postgres -W postgres -A app_user_password
set -e

HOST="localhost"
PORT="5432"
DB="roommatematch"
USER="postgres"
PASS=""
APP_PASS="app_user_password"

while getopts "h:p:d:U:W:A:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    d) DB="$OPTARG" ;;
    U) USER="$OPTARG" ;;
    W) PASS="$OPTARG" ;;
    A) APP_PASS="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

if ! command -v psql &> /dev/null; then
    echo "psql no encontrado. Instala PostgreSQL client tools."
    exit 1
fi

export PGPASSWORD="$PASS"
sed "s/'CHANGE_ME_IN_ENV'/'$APP_PASS'/g" "$(dirname "$0")/rls.sql" | \
    psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -v ON_ERROR_STOP=1
