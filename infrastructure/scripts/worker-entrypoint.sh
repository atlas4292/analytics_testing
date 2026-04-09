#!/bin/bash
set -e

echo "=== Starting Worker Node ==="

# Wait for the Nessie catalog to become available
echo "Waiting for Nessie at nessie:19120..."
until nc -z nessie 19120 2>/dev/null; do
    echo "  Nessie not ready — retrying in 5 s..."
    sleep 5
done
echo "Nessie catalog is available."

echo "Worker node ready."
echo "  Spark  : ${SPARK_HOME}"
echo "  Python : $(python3 --version)"

# Hand off to the CMD (default: tail -f /dev/null to keep the container alive)
exec "$@"
