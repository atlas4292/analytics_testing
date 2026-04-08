# Nessie + MinIO Analytics Infrastructure

This setup provides a complete data lakehouse catalog solution using Nessie with MinIO as the storage backend.

## Overview

- **Nessie**: Data catalog providing Git-like versioning for data lakes
- **MinIO**: S3-compatible object storage
- **Docker Compose**: Container orchestration

## Quick Start

1. **Start the full stack:**
   ```bash
   cd infrastructure/setup_scripts
   chmod +x start-nessie-stack.sh
   ./start-nessie-stack.sh
   ```

2. **Or start services manually:**
   ```bash
   cd infrastructure/compose
   
   # Start MinIO
   docker-compose up -d minio-storage
   
   # Setup buckets (wait a few seconds)
   docker-compose --profile setup up minio-client
   
   # Start Nessie
   docker-compose up -d nessie
   ```

## Access URLs

- **MinIO Console**: http://localhost:9001
  - Username: `minioadmin`
  - Password: `minioadmin123`
  
- **Nessie API**: http://localhost:19120/api/v1
  - Config endpoint: http://localhost:19120/api/v1/config

## Storage Configuration

### MinIO Buckets

The following buckets are automatically created:
- `analytics-data` - Main analytics datasets
- `raw-data` - Raw/unprocessed data
- `processed-data` - Cleaned/transformed data  
- `nessie-catalog` - **Nessie metadata storage**
- `temp-files` - Temporary files (auto-deleted after 7 days)
- `backups` - Backup storage

### Nessie Configuration

Nessie is configured to use MinIO as its storage backend:
- **Storage Type**: JDBC with S3-compatible MinIO backend
- **Bucket**: `nessie-catalog`
- **Endpoint**: `http://minio-storage:9000` (internal network)
- **Authentication**: MinIO credentials

## Usage Examples

### Python Client

1. **Install dependencies:**
   ```bash
   pip install -r infrastructure/examples/nessie_requirements.txt
   ```

2. **Run the example:**
   ```bash
   python infrastructure/examples/nessie_client_example.py
   ```

### Direct API Calls

```bash
# Check Nessie health
curl http://localhost:19120/api/v1/config

# List branches
curl http://localhost:19120/api/v1/trees

# List tables on main branch  
curl http://localhost:19120/api/v1/trees/branch/main/entries
```

## Integration with Analytics Tools

### Apache Iceberg + Spark
Nessie works excellently with Apache Iceberg tables:
```python
spark.conf.set("spark.sql.catalog.nessie", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.catalog.nessie.catalog-impl", "org.apache.iceberg.nessie.NessieCatalog")
spark.conf.set("spark.sql.catalog.nessie.uri", "http://localhost:19120/api/v1")
spark.conf.set("spark.sql.catalog.nessie.ref", "main")
```

### Dagster Integration
For data pipelines, Nessie can track data lineage and provide version control:
```python
from dagster import asset
from dagster_aws.s3 import s3_resource

@asset
def processed_data():
    # Process data and write to versioned table in Nessie
    pass
```

## Key Features

### Data Versioning
- **Git-like branching**: Create branches for data experiments
- **Time travel**: Query historical data states
- **Merge operations**: Combine changes from different branches

### Metadata Management
- **Schema evolution**: Track table schema changes over time
- **Data lineage**: Understand data dependencies and transformations
- **Governance**: Apply policies and access controls

### Integration
- **Spark**: Native integration with Apache Spark
- **Iceberg**: Works with Apache Iceberg table format
- **Delta Lake**: Compatible with Delta Lake tables
- **Dagster/Airflow**: Integrates with workflow orchestrators

## Troubleshooting

### Common Issues

1. **Nessie startup fails:**
   ```bash
   # Check Nessie logs
   docker-compose logs nessie
   
   # Ensure MinIO is running first
   docker-compose up -d minio-storage
   ```

2. **MinIO connection issues:**
   ```bash
   # Verify MinIO health
   curl http://localhost:9000/minio/health/live
   
   # Check bucket exists
   docker-compose exec minio-storage mc ls local/nessie-catalog
   ```

3. **Port conflicts:**
   - MinIO API: 9000
   - MinIO Console: 9001  
   - Nessie API: 19120
   
   Change ports in `docker-compose.yml` if needed.

### Health Checks

```bash
# Check all services
docker-compose ps

# Verify Nessie API
curl -f http://localhost:19120/api/v1/config

# Test MinIO access
curl -f http://localhost:9000/minio/health/live
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Applications  │───▶│     Nessie      │───▶│     MinIO       │
│   (Spark, etc.) │    │   (Catalog)     │    │   (Storage)     │
│                 │    │  Port: 19120    │    │  Port: 9000     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │                 │
                       │ JDBC Database   │
                       │ (H2 in-memory)  │
                       │                 │
                       └─────────────────┘
```

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (destroys data!)
docker-compose down -v
```