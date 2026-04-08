#!/bin/bash

# MinIO Setup Script - Creates initial buckets and configuration
set -e

echo "⏳ Waiting for MinIO to be ready..."
until mc alias set local http://minio-storage:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD; do
  echo "Waiting for MinIO server..."
  sleep 2
done

echo "✅ MinIO is ready! Setting up buckets..."

# Create common buckets for analytics workloads
buckets=(
  "analytics-data"
  "raw-data" 
  "processed-data"
  "dad-jokes"
  "dagster-tutorial"
  "dbt-test"
  "temp-files"
  "backups"
)

for bucket in "${buckets[@]}"; do
  if mc mb "local/$bucket" 2>/dev/null; then
    echo "✅ Created bucket: $bucket"
  else
    echo "ℹ️  Bucket $bucket already exists"
  fi
done

# Set bucket policies for easy access
echo "🔧 Setting bucket policies..."
for bucket in "${buckets[@]}"; do
  mc anonymous set public "local/$bucket" || echo "⚠️  Failed to set public policy for $bucket"
done

# Create a lifecycle policy for temp-files (auto-delete after 7 days)
echo "⏰ Setting lifecycle policies..."
cat > /tmp/lifecycle.json <<EOF
{
  "Rules": [
    {
      "ID": "DeleteTempFiles",
      "Status": "Enabled",
      "Expiration": {
        "Days": 7
      }
    }
  ]
}
EOF

mc ilm set --config /tmp/lifecycle.json local/temp-files || echo "⚠️  Failed to set lifecycle policy"

echo "🎉 MinIO setup complete!"
echo ""
echo "Access URLs:"
echo "  API:     http://localhost:9000"
echo "  Console: http://localhost:9001"
echo "  Login:   minioadmin / minioadmin123"
echo ""
echo "Available buckets:"
for bucket in "${buckets[@]}"; do
  echo "  - $bucket"
done