#!/bin/bash
set -e

PG_VERSION=16
PG_CLUSTER=main
PG_DATA="/var/lib/postgresql/${PG_VERSION}/${PG_CLUSTER}"
PG_CONF="/etc/postgresql/${PG_VERSION}/${PG_CLUSTER}"
PG_LOG="/var/log/postgresql/postgresql-${PG_VERSION}-${PG_CLUSTER}.log"

echo "=== Starting Management Node (PostgreSQL) ==="

# ---------------------------------------------------------------
# PostgreSQL Setup
# ---------------------------------------------------------------
echo "Setting up PostgreSQL..."

# On a fresh volume the data dir may be empty — re-create the cluster
if [ ! -s "${PG_DATA}/PG_VERSION" ]; then
    echo "Initialising PostgreSQL data directory..."
    pg_dropcluster --stop ${PG_VERSION} ${PG_CLUSTER} 2>/dev/null || true
    pg_createcluster ${PG_VERSION} ${PG_CLUSTER}

    # Apply network-access settings
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "${PG_CONF}/pg_hba.conf"
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONF}/postgresql.conf"
fi

# Ensure the runtime directory exists
mkdir -p /var/run/postgresql && chown postgres:postgres /var/run/postgresql

echo "Starting PostgreSQL..."
pg_ctlcluster ${PG_VERSION} ${PG_CLUSTER} start

 
echo "PostgreSQL is ready."

# Create application databases (idempotent)
if ! su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = 'dagster'\"" | grep -q 1; then
    echo "Creating application databases..."
    su - postgres -c "psql -f /opt/scripts/init-postgres-databases.sql"
    echo "Application databases created."
fi

echo "Management node ready — PostgreSQL listening on port 5432."

# ---------------------------------------------------------------
# Dagster Webserver
# ---------------------------------------------------------------
echo "Starting Dagster webserver on port 3000..."
mkdir -p "${DAGSTER_HOME}"
dagster-webserver -h 0.0.0.0 -p 3000 &

echo "Dagster webserver started."

# Keep container alive by tailing the log (pg_ctlcluster runs in the background)
exec tail -f "${PG_LOG}"
