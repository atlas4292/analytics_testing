#!/bin/bash

# Nessie + MinIO Quick Start Script
# This script starts the complete stack and sets up the environment

set -e

echo "🚀 Starting Nessie + MinIO Analytics Stack"
echo "=" * 50

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "❌ Docker or Docker Compose not found. Please install Docker first."
    exit 1
fi

COMPOSE_CMD="docker-compose"
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
fi

cd "$(dirname "$0")/../compose"

echo "🧹 Cleaning up any existing containers..."
$COMPOSE_CMD down --remove-orphans

echo "🏗️ Building and starting services..."
$COMPOSE_CMD up -d minio-storage

echo "⏳ Waiting for MinIO to be ready..."
sleep 10

echo "🪣 Setting up MinIO buckets..."
$COMPOSE_CMD --profile setup up minio-client

echo "🗄️ Starting Nessie catalog..."
$COMPOSE_CMD up -d nessie

echo "⏳ Waiting for Nessie to be ready..."
sleep 20

# Health check
echo "🩺 Running health checks..."

# Check MinIO
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    echo "✅ MinIO is running"
else
    echo "⚠️ MinIO might not be ready yet"
fi

# Check Nessie
if curl -s http://localhost:19120/api/v1/config > /dev/null; then
    echo "✅ Nessie is running"
else
    echo "⚠️ Nessie might not be ready yet (this is normal on first start)"
fi

echo ""
echo "🎉 Stack started successfully!"
echo ""
echo "Access URLs:"
echo "  📊 MinIO Console: http://localhost:9001"
echo "      Username: minioadmin"
echo "      Password: minioadmin123"
echo ""
echo "  🗄️ Nessie API: http://localhost:19120/api/v1"
echo "      Health: http://localhost:19120/api/v1/config"
echo ""
echo "Available MinIO Buckets:"
echo "  - analytics-data"
echo "  - raw-data"
echo "  - processed-data"
echo "  - nessie-catalog (Nessie metadata)"
echo "  - temp-files"
echo "  - backups"
echo ""
echo "Next steps:"
echo "  1. Install Python dependencies: pip install -r ../examples/nessie_requirements.txt"
echo "  2. Run the example: python ../examples/nessie_client_example.py"
echo "  3. Access MinIO Console to view data"
echo "  4. Use Nessie API for catalog operations"
echo ""
echo "To stop the stack: $COMPOSE_CMD down"