# Analytics Testing Repository

A comprehensive testing environment for modern data analytics tools and workflows, featuring multiple interconnected projects for learning and experimenting with data engineering technologies.

## 🏗️ Architecture Overview

This repository provides a complete analytics stack including:

- **Data Orchestration**: Dagster workflows for pipeline management
- **Data Transformation**: dbt models for analytics engineering
- **Object Storage**: MinIO for S3-compatible data lake
- **Data Catalog**: Nessie for Git-like version control of table metadata
- **Table Format**: Apache Iceberg for open table format support
- **Processing Engine**: Apache Spark with Iceberg and Hive integration
- **Metadata Store**: PostgreSQL for shared database services (Dagster, Nessie JDBC, Hive Metastore)
- **Alternative Languages**: Scala for JVM-based analytics
- **Infrastructure**: Docker Compose for local development

## 📁 Project Structure

```
├── dg.toml                         # Dagster workspace configuration
├── Makefile                        # Infrastructure management commands
├── deployments/
│   └── local/                      # Local deployment configs
├── infrastructure/
│   ├── compose/                    # Docker Compose orchestration
│   │   └── docker-compose.yml
│   ├── conf/                       # Hadoop/Spark/Hive configuration
│   │   ├── core-site.xml
│   │   ├── hive-site.xml
│   │   ├── spark-defaults.conf
│   │   └── spark-hive-site.xml
│   ├── dockerfiles/                # Container definitions
│   │   ├── Dockerfile.management   # PostgreSQL management node
│   │   ├── Dockerfile.minion       # MinIO storage node
│   │   └── Dockerfile.worker       # Spark + Dagster worker node
│   ├── examples/                   # Client examples and tests
│   │   ├── minio_client_example.py
│   │   ├── nessie_client_example.py
│   │   ├── nessie_requirements.txt
│   │   └── nessie_simple_test.py
│   ├── scripts/                    # Container entrypoints and init scripts
│   │   ├── init-metastore-db.sql
│   │   ├── init-postgres-databases.sql
│   │   ├── management-entrypoint.sh
│   │   ├── minio-setup.sh
│   │   ├── start-nessie-stack.sh
│   │   └── worker-entrypoint.sh
│   └── setup_scripts/              # Host-level setup helpers
│       ├── minio-setup.sh
│       └── start-nessie-stack.sh
├── projects/
│   ├── dagster-tutorial/           # Tutorial Dagster project
│   ├── dad-jokes/                  # Sample Dagster project
│   ├── dbt-test/                   # dbt transformation project
│   └── scala-test/                 # Scala analytics project
├── setup_scripts/                  # System setup utilities (e.g. Hadoop install)
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.12+
- [uv](https://docs.astral.sh/uv/) for Python package management

### 1. Infrastructure Setup

Start the full analytics stack:

```bash
# Build all containers
make build

# Start MinIO storage
make up

# Setup initial storage buckets
make setup-buckets
```

The full stack is orchestrated via Docker Compose and includes:

| Service          | Container       | Port(s)                  | Description                        |
|------------------|-----------------|--------------------------|------------------------------------|
| MinIO            | minio-storage   | 9000 (API), 9001 (UI)   | S3-compatible object storage       |
| Nessie           | nessie          | 19120                    | Data catalog with REST API         |
| PostgreSQL       | management      | 5432                     | Shared metadata database           |
| Spark + Dagster  | spark-worker    | 3000 (Dagster), 4040 (Spark UI) | Processing and orchestration |
| MinIO Replica    | minio-replica   | 9010 (API), 9002 (UI)   | Optional replication instance      |

**Service URLs**:
- MinIO Console: http://localhost:9001 (minioadmin / minioadmin123)
- MinIO API: http://localhost:9000
- Nessie API: http://localhost:19120
- Dagster UI: http://localhost:3000
- Spark UI: http://localhost:4040

### 2. Dagster Projects

Navigate to any Dagster project and install dependencies:

```bash
# For dagster-tutorial
cd projects/dagster-tutorial
uv sync

# Start Dagster UI
dagster dev
```

Access Dagster UI at http://localhost:3000

### 3. dbt Transformations

Run dbt models:

```bash
cd projects/dbt-test/dbt
dbt run
dbt test
```

## 📊 Projects Overview

### Dagster Tutorial

**Location**: `projects/dagster-tutorial/`

A learning project demonstrating Dagster capabilities with:
- **Data Sources**: Jaffle Shop sample data (customers, orders, payments)
- **Real Estate Data**: Florida property sales dataset
- **Pokemon Dataset**: Complete Gen1-Gen9 data
- **Weather Data**: Meteorological information
- **Storage Backend**: DuckDB for analytics

**Key Features**:
- Asset-based data pipeline definitions
- Data ingestion from CSV and web sources
- DuckDB integration for analytical queries

### dbt Test Project

**Location**: `projects/dbt-test/`

A complete dbt project showcasing modern analytics engineering:
- **Staging Models**: Raw data cleanup and standardization
- **Marts**: Business logic and final transformations
- **Seeds**: Static reference data
- **Documentation**: Comprehensive data lineage

**Data Models**:
- Customer lifetime value analysis
- Order analytics and trends
- Payment method analysis

### Dad Jokes Project

**Location**: `projects/dad-jokes/`

A sample Dagster project with basic structure for experimentation.

### Scala Test Project

**Location**: `projects/scala-test/`

Basic Scala environment for JVM-based analytics exploration.

## 🛠️ Available Commands

### Infrastructure Management (Makefile)

```bash
make help           # Show all available commands
make build          # Build containers
make up             # Start MinIO service
make down           # Stop all services
make restart        # Restart services
make logs           # View MinIO logs
make logs-f         # Follow MinIO logs
make setup-buckets  # Initialize storage buckets
make clean          # Remove containers and volumes
make replica        # Start with MinIO replication
make shell          # Open shell in MinIO container
make mc-shell       # Open MinIO client shell
make status         # Check service status and URLs
make test           # Test S3 connectivity
```

### Development Workflow

```bash
# Install dependencies for a project
cd projects/{project-name}
uv sync

# Run Dagster development server
dagster dev

# Run dbt transformations
cd projects/dbt-test/dbt
dbt run
dbt test
dbt docs generate
dbt docs serve
```

## 🗃️ Data Sources

### Sample Datasets

1. **Jaffle Shop Data**: Classic e-commerce analytics dataset
   - Customers, orders, and payments
   - Used across both Dagster and dbt projects

2. **Florida Real Estate**: Property sales data
   - Comprehensive real estate transactions
   - Located in `dagster-tutorial/data/`

3. **Pokemon Complete Dataset**: Gaming analytics data
   - Multi-generational Pokemon statistics
   - Useful for time series and categorical analysis

4. **Weather Data**: Meteorological information
   - Climate and weather patterns
   - Good for IoT and sensor data simulation

## 🔧 Configuration

### Environment Variables

Key configuration files:
- `dg.toml`: Dagster workspace settings
- `pyproject.toml`: Python dependencies per project
- `infrastructure/compose/docker-compose.yml`: Infrastructure orchestration
- `infrastructure/conf/`: Hadoop, Spark, and Hive configuration

### Storage Configuration

MinIO is configured with:
- **Data Storage**: Persistent Docker volumes
- **Access**: S3-compatible API
- **Replication**: Optional second instance for testing
- **Setup**: Automated bucket creation

### Iceberg + Nessie Configuration

The worker node is pre-configured with PyIceberg to use Nessie as a REST catalog:
- **Catalog Type**: REST (via Nessie Iceberg REST API)
- **Nessie URI**: `http://nessie:19120/iceberg`
- **Warehouse Path**: `s3a://analytics-data/warehouse`
- **S3 Backend**: MinIO with path-style access

### Spark Configuration

Spark is configured via `infrastructure/conf/` with:
- `spark-defaults.conf`: Iceberg catalog and S3A connector settings
- `core-site.xml`: Hadoop S3A filesystem configuration
- `hive-site.xml` / `spark-hive-site.xml`: Hive Metastore integration

## 📚 Learning Resources

This repository is designed for learning and testing:

1. **Data Orchestration**: Explore Dagster's asset-based approach
2. **Analytics Engineering**: Practice dbt modeling patterns
3. **Object Storage**: Understand S3-compatible data lakes
4. **Data Catalogs**: Use Nessie for Git-like table versioning
5. **Table Formats**: Work with Apache Iceberg for open lakehouse patterns
6. **Processing Engines**: Run Spark jobs with Iceberg integration
7. **Containerization**: Learn Docker-based development
8. **Multi-language Analytics**: Compare Python and Scala approaches

## 🐛 Troubleshooting

### Common Issues

**Docker Build Failures**:
```bash
make down && make clean
make build && make up
```

**MinIO Connection Issues**:
```bash
make status
make test
```

**Nessie Not Starting**:
- Nessie depends on MinIO being available; check MinIO is running first
- Verify health check: `curl http://localhost:19120/api/v1/config`

**Dagster Asset Materialization Failures**:
- Check data file paths in asset definitions
- Verify DuckDB connection in resources
- Ensure the worker container is running: `docker ps | grep spark-worker`

**dbt Model Failures**:
- Ensure source data is available
- Check profile configuration in `profiles.yml`

### Useful Debugging Commands

```bash
# Check all container statuses
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View detailed logs for a specific service
make logs-f

# Access MinIO client shell
make mc-shell

# Check Nessie health
curl http://localhost:19120/api/v1/config

# Check PostgreSQL
docker exec management pg_isready -h localhost -U postgres

# Check Dagster asset status
dagster asset list
```

## 🤝 Contributing

This is a learning repository. Feel free to:

1. Add new datasets to explore
2. Create additional Dagster assets
3. Extend dbt models with new transformations
4. Experiment with different storage backends
5. Add monitoring and observability tools

## 📄 License

This project is for educational and testing purposes. Individual datasets may have their own licensing terms.