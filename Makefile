# MinIO S3-Compatible Storage Management
.PHONY: help build up down restart logs clean setup-buckets

# Default target
help:
	@echo "Available commands:"
	@echo "  build          - Build the MinIO container"
	@echo "  up             - Start MinIO storage service"
	@echo "  down           - Stop MinIO service"
	@echo "  restart        - Restart MinIO service"
	@echo "  logs           - Show MinIO logs"
	@echo "  logs-f         - Follow MinIO logs"
	@echo "  setup-buckets  - Create initial buckets and configure MinIO"
	@echo "  clean          - Remove containers and volumes"
	@echo "  shell          - Open shell in MinIO container"
	@echo "  status         - Check MinIO status"
	@echo "  replica        - Start with replication (2 MinIO instances)"
	@echo "  mc-shell       - Open MinIO client shell for management"

# Build the MinIO container
build:
	cd docker && docker-compose build

# Start MinIO service
up:
	cd docker && docker-compose up -d minio-storage

# Start with replica
replica:
	cd docker && docker-compose --profile replica up -d

# Stop MinIO service
down:
	cd docker && docker-compose down

# Restart MinIO service
restart: down up

# Show logs
logs:
	cd docker && docker-compose logs minio-storage

# Follow logs
logs-f:
	cd docker && docker-compose logs -f minio-storage

# Setup initial buckets
setup-buckets:
	cd docker && chmod +x minio-setup.sh && docker-compose --profile setup run --rm minio-client

# Open shell in MinIO container
shell:
	cd docker && docker-compose exec minio-storage sh

# Open MinIO client shell for management
mc-shell:
	cd docker && docker-compose run --rm minio-client sh

# Clean up containers and volumes
clean:
	cd docker && docker-compose down -v --remove-orphans
	docker system prune -f

# Check status
status:
	cd docker && docker-compose ps
	@echo ""
	@echo "MinIO Console: http://localhost:9001"
	@echo "MinIO API:     http://localhost:9000"
	@echo "Login:         minioadmin / minioadmin123"

# Test S3 connectivity
test:
	@echo "Testing S3 connectivity..."
	cd docker && docker-compose run --rm minio-client mc ls local/ || echo "MinIO not accessible"