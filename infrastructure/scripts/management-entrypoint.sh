#!/bin/bash
set -e

PG_VERSION=16
PG_DATA="/var/lib/postgresql/${PG_VERSION}/main"
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PG_LOG="/var/log/postgresql/postgresql-${PG_VERSION}.log"

echo "=== Starting Management Node (PostgreSQL) ==="

# ---------------------------------------------------------------
# PostgreSQL Setup
# ---------------------------------------------------------------
echo "Setting up PostgreSQL..."

# Initialise the data directory if the volume is empty (first run)
if [ ! -s "${PG_DATA}/PG_VERSION" ]; then
    echo "Initialising PostgreSQL data directory..."
    mkdir -p "${PG_DATA}"
    chown postgres:postgres "${PG_DATA}"
    chmod 700 "${PG_DATA}"
    su - postgres -c "${PG_BIN}/initdb -D ${PG_DATA}"

    # Apply network-access settings to the freshly-created cluster
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "${PG_DATA}/pg_hba.conf"
    {
        echo "listen_addresses = '*'"
        echo "port = 5432"
    } >> "${PG_DATA}/postgresql.conf"
fi

# Ensure the runtime directory exists
mkdir -p /var/run/postgresql && chown postgres:postgres /var/run/postgresql

echo "Starting PostgreSQL..."
su - postgres -c "${PG_BIN}/pg_ctl start -D ${PG_DATA} -l ${PG_LOG} -w"

# Wait for PostgreSQL to accept connections
echo "Waiting for PostgreSQL to become ready..."
until su - postgres -c "${PG_BIN}/pg_isready -h localhost" >/dev/null 2>&1; do
    sleep 1
done
echo "PostgreSQL is ready."

# Create application databases (idempotent)
if ! su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = 'dagster'\"" | grep -q 1; then
    echo "Creating application databases..."
    su - postgres -c "psql -f /opt/scripts/init-postgres-databases.sql"
    echo "Application databases created."
fi

echo "Management node ready — PostgreSQL listening on port 5432."

# Keep container alive by tailing the log (pg_ctl runs in the background)
exec tail -f "${PG_LOG}"
