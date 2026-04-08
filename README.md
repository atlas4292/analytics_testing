# Analytics Testing Repository

A comprehensive testing environment for modern data analytics tools and workflows, featuring multiple interconnected projects for learning and experimenting with data engineering technologies.

## 🏗️ Architecture Overview

This repository provides a complete analytics stack including:

- **Data Orchestration**: Dagster workflows for pipeline management
- **Data Transformation**: dbt models for analytics engineering
- **Object Storage**: MinIO for S3-compatible data lake
- **Alternative Languages**: Scala for JVM-based analytics
- **Infrastructure**: Docker Compose for local development

## 📁 Project Structure

```
├── dg.toml                     # Dagster workspace configuration
├── Makefile                    # MinIO management commands
├── deployments/
│   └── local/                  # Local deployment configs
├── infrastructure/
│   ├── compose/                # Docker orchestration
│   ├── dockerfiles/            # Container definitions
│   └── setup_scripts/          # Infrastructure setup
├── projects/
│   ├── dagster-tutorial/       # Tutorial Dagster project
│   ├── dad-jokes/              # Sample Dagster project
│   ├── dbt-test/               # dbt transformation project
│   └── scala-test/             # Scala analytics project
└── setup_scripts/             # System setup utilities
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- [uv](https://docs.astral.sh/uv/) for Python package management

### 1. Infrastructure Setup

Start the MinIO object storage service:

```bash
# Build and start MinIO
make build
make up

# Setup initial buckets
make setup-buckets

# Check status
make logs
```

MinIO will be available at:
- **API**: http://localhost:9000
- **Console UI**: http://localhost:9001
- **Credentials**: minioadmin / minioadmin123

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

### MinIO Management

```bash
make help           # Show all available commands
make up             # Start MinIO service
make down           # Stop services
make logs           # View logs
make setup-buckets  # Initialize storage buckets
make clean          # Remove containers and volumes
make replica        # Start with replication
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
- `docker-compose.yml`: Infrastructure orchestration

### Storage Configuration

MinIO is configured with:
- **Data Storage**: Persistent Docker volumes
- **Access**: S3-compatible API
- **Replication**: Optional second instance for testing
- **Setup**: Automated bucket creation

## 📚 Learning Resources

This repository is designed for learning and testing:

1. **Data Orchestration**: Explore Dagster's asset-based approach
2. **Analytics Engineering**: Practice dbt modeling patterns  
3. **Object Storage**: Understand S3-compatible data lakes
4. **Containerization**: Learn Docker-based development
5. **Multi-language Analytics**: Compare Python and Scala approaches

## 🐛 Troubleshooting

### Common Issues

**MinIO Connection Issues**:
```bash
make down && make clean
make build && make up
```

**Dagster Asset Materialization Failures**:
- Check data file paths in asset definitions
- Verify DuckDB connection in resources

**dbt Model Failures**:
- Ensure source data is available
- Check profile configuration in `profiles.yml`

### Useful Debugging Commands

```bash
# Check MinIO container status
docker ps | grep minio

# View detailed logs
make logs-f

# Access MinIO client shell
make mc-shell

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