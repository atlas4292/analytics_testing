#!/bin/bash
set -e

echo "=== Starting Worker Node ==="

# Wait for the Hive Metastore on the management node to become available
echo "Waiting for Hive Metastore at management:9083..."
until nc -z management 9083 2>/dev/null; do
    echo "  Metastore not ready — retrying in 5 s..."
    sleep 5
done
echo "Hive Metastore is available."

# Ensure DAGSTER_HOME exists
mkdir -p "${DAGSTER_HOME}"

echo "Worker node ready."
echo "  Spark  : ${SPARK_HOME}"
echo "  Python : $(python3 --version)"
echo "  Dagster: $(dagster --version 2>/dev/null || echo 'not installed')"

# Hand off to the CMD (default: tail -f /dev/null to keep the container alive)
exec "$@"
