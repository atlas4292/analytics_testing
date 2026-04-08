-- Create the Hive Metastore database and user in PostgreSQL
CREATE USER hive WITH PASSWORD 'hive';
CREATE DATABASE metastore OWNER hive;
GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;

\c metastore
GRANT ALL ON SCHEMA public TO hive;
