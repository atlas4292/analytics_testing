# Analytics Testing — Infrastructure Management
COMPOSE = cd infrastructure/compose && docker-compose

.PHONY: help build up down restart logs logs-f clean status \
        setup-buckets replica \
        minio-up minio-down minio-logs minio-shell mc-shell \
        nessie-up nessie-down nessie-logs \
        management-up management-down management-logs management-shell \
        worker-up worker-down worker-logs worker-shell

# ─── Main Commands ────────────────────────────────────────────────

# Default target
help:
	@echo "Main commands:"
	@echo "  build              - Build all containers"
	@echo "  up                 - Start all services"
	@echo "  down               - Stop all services"
	@echo "  restart            - Restart all services"
	@echo "  logs               - Show logs for all services"
	@echo "  logs-f             - Follow logs for all services"
	@echo "  status             - Show status and service URLs"
	@echo "  clean              - Remove all containers and volumes"
	@echo "  setup-buckets      - Create initial MinIO buckets"
	@echo "  replica            - Start with MinIO replication"
	@echo ""
	@echo "Per-component commands:"
	@echo "  minio-up/down/logs/shell   - Manage MinIO storage"
	@echo "  mc-shell                   - Open MinIO client shell"
	@echo "  nessie-up/down/logs        - Manage Nessie catalog"
	@echo "  management-up/down/logs/shell - Manage PostgreSQL"
	@echo "  worker-up/down/logs/shell  - Manage Spark/Dagster worker"

# Build all containers
build:
	$(COMPOSE) build

# Start all services
up:
	$(COMPOSE) up -d

# Stop all services
down:
	$(COMPOSE) down

# Restart all services
restart: down up

# Show logs for all services
logs:
	$(COMPOSE) logs

# Follow logs for all services
logs-f:
	$(COMPOSE) logs -f

# Clean up all containers and volumes
clean:
	$(COMPOSE) down -v --remove-orphans
	docker system prune -f

# Check status
status:
	$(COMPOSE) ps
	@echo ""
	@echo "Service URLs:"
	@echo "  MinIO Console:  http://localhost:9001  (minioadmin / minioadmin123)"
	@echo "  MinIO API:      http://localhost:9000"
	@echo "  Nessie API:     http://localhost:19120"
	@echo "  Dagster UI:     http://localhost:3000"
	@echo "  Spark UI:       http://localhost:4040"
	@echo "  PostgreSQL:     localhost:5432"

# Setup initial buckets
setup-buckets:
	chmod +x infrastructure/scripts/minio-setup.sh && $(COMPOSE) --profile setup run --rm minio-client

# Start with MinIO replica
replica:
	$(COMPOSE) --profile replica up -d

# ─── MinIO ────────────────────────────────────────────────────────

minio-up:
	$(COMPOSE) up -d minio-storage

minio-down:
	$(COMPOSE) stop minio-storage

minio-logs:
	$(COMPOSE) logs -f minio-storage

minio-shell:
	$(COMPOSE) exec minio-storage sh

mc-shell:
	$(COMPOSE) run --rm minio-client sh

# ─── Nessie ───────────────────────────────────────────────────────

nessie-up:
	$(COMPOSE) up -d nessie

nessie-down:
	$(COMPOSE) stop nessie

nessie-logs:
	$(COMPOSE) logs -f nessie

# ─── Management (PostgreSQL) ─────────────────────────────────────

management-up:
	$(COMPOSE) up -d management

management-down:
	$(COMPOSE) stop management

management-logs:
	$(COMPOSE) logs -f management

management-shell:
	$(COMPOSE) exec management psql -U postgres

# ─── Worker (Spark + Dagster) ────────────────────────────────────

worker-up:
	$(COMPOSE) up -d worker

worker-down:
	$(COMPOSE) stop worker

worker-logs:
	$(COMPOSE) logs -f worker

worker-shell:
	$(COMPOSE) exec spark-worker bash

# ─── Testing ─────────────────────────────────────────────────────

test:
	@echo "Testing S3 connectivity..."
	$(COMPOSE) run --rm minio-client mc ls local/ || echo "MinIO not accessible"