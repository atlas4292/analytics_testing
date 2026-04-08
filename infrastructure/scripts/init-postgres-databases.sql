-- Create application databases and users in PostgreSQL
-- (Hive Metastore removed — Nessie serves as the Iceberg catalog)

-- Dagster run/event/schedule storage
CREATE USER dagster WITH PASSWORD 'dagster';
CREATE DATABASE dagster OWNER dagster;
GRANT ALL PRIVILEGES ON DATABASE dagster TO dagster;

-- Nessie JDBC backend (optional — wire Nessie to this instead of H2)
CREATE USER nessie WITH PASSWORD 'nessie';
CREATE DATABASE nessie OWNER nessie;
GRANT ALL PRIVILEGES ON DATABASE nessie TO nessie;

\c dagster
GRANT ALL ON SCHEMA public TO dagster;

\c nessie
GRANT ALL ON SCHEMA public TO nessie;
