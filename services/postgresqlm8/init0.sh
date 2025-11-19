#!/bin/bash
set -e 
# set -e: "exit on error"

# Read Docker secrets
DB_USER="cpt_dbuser"
DB_PASSWORD=$(cat /run/secrets/postgresql_user_password 2>/dev/null)
DB_NAME="${POSTGRES_DB}"

# Generate SQL commands using the secrets
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
    GRANT CONNECT ON DATABASE ${DB_NAME} to ${DB_USER};
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
    ALTER DATABASE ${DB_NAME} OWNER to ${DB_USER};
EOSQL