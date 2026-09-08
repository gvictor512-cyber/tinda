#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
      CREATE USER app_user WITH PASSWORD '$APP_USER_PASSWORD';
    ELSE
      ALTER USER app_user WITH PASSWORD '$APP_USER_PASSWORD';
    END IF;
  END
  \$\$;

  GRANT CONNECT ON DATABASE "$POSTGRES_DB" TO app_user;
EOSQL
