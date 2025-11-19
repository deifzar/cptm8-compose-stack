#!/bin/bash

# Unified build script for CMPTM8 with secure secrets management
# Usage: ./build.sh [environment] [options]
# Example: ./build.sh production --no-cache

set -e  # Exit on error

# Default values
ENVIRONMENT="dev"
BACKEND_COMPOSE_FILE="docker-compose-backend.yml"
FRONTEND_COMPOSE_FILE="docker-compose-frontend.yml"
ENV_FILE=".env"
BUILD_ARGS=""
COMPOSE_ARGS=""
RUN_MODE="both"  # Options: backend, frontend, both
# Minimal backend services required for frontend
MINIMAL_BACKEND_SERVICES=("postgresqlm8" "mongodb-1" "mongodb-2" "mongodb-3" "mongodb-init" "rabbitmqm8")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo -e "${BLUE}🚀 CPTM8 Two-Stage Build Script${NC}"
    echo "======================================"
    echo ""
    echo "Usage: $0 [environment] [options|commands]"
    echo ""
    echo "Environments:"
    echo "  dev            Build for development (default)"
    echo "  prod           Build for production"
    echo "  staging        Build for staging"
    echo ""
    echo "Commands:"
    echo "  stop           Stop all running services"
    echo ""
    echo "Options:"
    echo "  --no-cache        Force rebuild without Docker cache"
    echo "  --pull            Pull latest base images"
    echo "  --build-only      Build services without starting them"
    echo "  --backend-only    Build and run only backend services"
    echo "  --frontend-only   Build and run only frontend services"
    echo "                    (Auto-starts minimal backend if not running: PostgreSQL, MongoDB, RabbitMQ)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Build Strategy:"
    echo "  Default: Backend → Frontend (two-stage sequential build)"
    echo "  --backend-only: Backend (PostgreSQL, MongoDB, RabbitMQ, Vector, OpenSearch, OpenSearch Dashboard, ASMM8, NaabuM8, KatanaM8, NuM8, ReportingM8, OrchestratorM8)"
    echo "  --frontend-only: Frontend (DashboardM8, SocketM8)"
    echo "                   If backend not running, prompts to start minimal backend (PostgreSQL, MongoDB, RabbitMQ)"
    echo ""
    echo "Examples:"
    echo "  $0                                   # Development two-stage build (both backend and frontend)"
    echo "  $0 prod                              # Production two-stage build"
    echo "  $0 dev --no-cache                    # Force rebuild both stages"
    echo "  $0 --backend-only                    # Build and run only backend services"
    echo "  $0 --frontend-only                   # Build and run frontend (prompts to start minimal backend if needed)"
    echo "  $0 dev --backend-only --no-cache     # Rebuild backend only"
    echo "  $0 dev --frontend-only --no-cache    # Rebuild frontend (starts minimal backend if needed)"
    echo "  $0 stop                              # Stop all services"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking Prerequisites${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Error: Docker is not installed${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Error: Docker Compose (v2) is not installed${NC}"
        exit 1
    fi
    
    # Check compose files based on run mode
    if [ "$RUN_MODE" = "backend" ] || [ "$RUN_MODE" = "both" ]; then
        if [ ! -f "$BACKEND_COMPOSE_FILE" ]; then
            echo -e "${RED}❌ Error: $BACKEND_COMPOSE_FILE not found${NC}"
            exit 1
        fi
    fi

    if [ "$RUN_MODE" = "frontend" ] || [ "$RUN_MODE" = "both" ]; then
        if [ ! -f "$FRONTEND_COMPOSE_FILE" ]; then
            echo -e "${RED}❌ Error: $FRONTEND_COMPOSE_FILE not found${NC}"
            exit 1
        fi
    fi
    
    # Check environment file
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}❌ Error: Environment file $ENV_FILE not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to validate secrets
validate_secrets() {
    echo -e "${BLUE}🔐 Validating Secrets${NC}"
    
    local secrets_dir="./secrets"
    local required_secrets=(
        "auth_secret.txt"
        "aws_key.txt"
        "aws_secret.txt"
        "google_client_id.txt"
        "google_client_secret.txt"
        "mongodb_database_url.txt"
        "mongodb_root_password.txt"
        "mongodb_user_password.txt"
        "opensearch_admin_password.txt"
        "postgresql_database_url.txt"
        "postgresql_root_password.txt"
        "postgresql_user_password.txt"
        "rabbitmq_url.txt"
        "rabbitmq_password.txt"
        "rabbitmq_username.txt"
        "smtp_password.txt"
        "smtp_username.txt"
    )
    
    if [ ! -d "$secrets_dir" ]; then
        echo -e "${RED}❌ Error: Secrets directory not found: $secrets_dir${NC}"
        exit 1
    fi
    
    local missing_secrets=()
    for secret in "${required_secrets[@]}"; do
        if [ ! -f "$secrets_dir/$secret" ]; then
            missing_secrets+=("$secret")
        fi
    done
    
    if [ ${#missing_secrets[@]} -ne 0 ]; then
        echo -e "${RED}❌ Error: Missing required secret files:${NC}"
        for secret in "${missing_secrets[@]}"; do
            echo -e "  - $secrets_dir/$secret"
        done
        echo -e "\n${YELLOW}💡 Create these files with your actual secrets${NC}"
        exit 1
    fi
    
    # Check for placeholder values
    local placeholder_warnings=()
    if grep -q "your-" "$secrets_dir"/google_client_*.txt "$secrets_dir"/smtp_*.txt "$secrets_dir"/aws_*.txt 2>/dev/null; then
        placeholder_warnings=("Some secret files contain placeholder values")
    fi
    
    if [ ${#placeholder_warnings[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Warning: Some secrets contain placeholder values${NC}"
        echo -e "${YELLOW}   Update them with real values before production deployment${NC}"
    fi
    
    echo -e "${GREEN}✅ Core secrets validation passed${NC}"
}

# Function to validate build environment
validate_build_env() {
    echo -e "${BLUE}🔧 Validating Build Environment${NC}"
    
    if [ ! -f ".env.build" ]; then
        echo -e "${RED}❌ Error: .env.build file not found${NC}"
        echo -e "${YELLOW}💡 This file should contain database URLs for Prisma generation${NC}"
        exit 1
    fi
    
    # Check if .env.build contains required database URLs
    if ! grep -q "PPG_DATABASE_URL=" .env.build || ! grep -q "PMG_DATABASE_URL=" .env.build; then
        echo -e "${RED}❌ Error: .env.build missing required database URLs${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Build environment validation passed${NC}"
}

# Function to set environment-specific settings
setup_environment() {
    case "$ENVIRONMENT" in
        dev)
            echo -e "${BLUE}🔨 Setting up Development Environment${NC}"
            BUILD_ARGS="--pull"
            ;;
        staging)
            echo -e "${YELLOW}🔨 Setting up Staging Environment${NC}"
            BUILD_ARGS="--pull --no-cache"
            ;;
        prod)
            echo -e "${RED}🔨 Setting up Production Environment${NC}"
            BUILD_ARGS="--pull --no-cache"
            echo -e "${YELLOW}⚠️  Remove development ports before production deployment!${NC}"
            ;;
        *)
            echo -e "${RED}❌ Error: Unknown environment: $ENVIRONMENT${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Function to show build summary
show_build_summary() {
    echo -e "\n${PURPLE}📋 Build Summary${NC}"
    echo "======================"
    echo -e "Environment: ${GREEN}$ENVIRONMENT${NC}"
    echo -e "Run Mode: ${GREEN}$RUN_MODE${NC}"

    if [ "$RUN_MODE" = "backend" ] || [ "$RUN_MODE" = "both" ]; then
        echo -e "Backend Compose: ${GREEN}$BACKEND_COMPOSE_FILE${NC}"
    fi
    if [ "$RUN_MODE" = "frontend" ] || [ "$RUN_MODE" = "both" ]; then
        echo -e "Frontend Compose: ${GREEN}$FRONTEND_COMPOSE_FILE${NC}"
    fi

    echo -e "Environment File: ${GREEN}$ENV_FILE${NC}"
    echo -e "Build Args: ${GREEN}$BUILD_ARGS${NC}"
    echo -e "Compose Args: ${GREEN}$COMPOSE_ARGS${NC}"
    echo ""

    case "$RUN_MODE" in
        backend)
            echo -e "Build Strategy: ${BLUE}Backend Only${NC}"
            ;;
        frontend)
            echo -e "Build Strategy: ${BLUE}Frontend Only${NC}"
            ;;
        both)
            echo -e "Build Strategy: ${BLUE}Backend → Frontend${NC}"
            ;;
    esac

    if [ "$RUN_MODE" = "backend" ] || [ "$RUN_MODE" = "both" ]; then
        echo -e "\n${BLUE}Backend Services:${NC}"
        echo -e "  ${GREEN}✓${NC} postgresql (PostgreSQL database)"
        echo -e "  ${GREEN}✓${NC} mongodb-1/2/3 (MongoDB replica set)"
        echo -e "  ${GREEN}✓${NC} rabbitmqm8 (RabbitMQ message queue)"
        echo -e "  ${GREEN}✓${NC} opensearch-node1/2 (Opensearch database nodes)"
        echo -e "  ${GREEN}✓${NC} opensearch-dashboard (Opensearch Dashboard)"
        echo -e "  ${GREEN}✓${NC} vectorm8 (Vector data pipeline)"
        echo -e "  ${GREEN}✓${NC} asmm8 (Host discovery service)"
        echo -e "  ${GREEN}✓${NC} naabum8 (Port discover service)"
        echo -e "  ${GREEN}✓${NC} katanam8 (Web Crawler service)"
        echo -e "  ${GREEN}✓${NC} num8 (Nuclei scanner)"
        echo -e "  ${GREEN}✓${NC} reportingm8 (Reporting service)"
        echo -e "  ${GREEN}✓${NC} orchestratorm8 (Orchestrator scanner service)"
    fi

    if [ "$RUN_MODE" = "frontend" ] || [ "$RUN_MODE" = "both" ]; then
        echo -e "\n${BLUE}Frontend Services:${NC}"
        echo -e "  ${GREEN}✓${NC} dashboardm8 (Next.js application)"
        echo -e "  ${GREEN}✓${NC} socketm8 (Socket.IO server)"
    fi
    echo ""
}

# Function to build and start minimal backend services
build_minimal_backend() {
    echo -e "\n${PURPLE}📦 Starting Minimal Backend Services${NC}"
    echo "=========================================="
    echo -e "${BLUE}Building only: PostgreSQL, MongoDB, RabbitMQ${NC}"

    # Build minimal services
    local services_list="${MINIMAL_BACKEND_SERVICES[@]}"
    local backend_cmd="docker compose --env-file $ENV_FILE -f $BACKEND_COMPOSE_FILE build $BUILD_ARGS $services_list"
    echo -e "${BLUE}Building minimal backend: ${GREEN}$backend_cmd${NC}"

    if eval $backend_cmd; then
        echo -e "${GREEN}✅ Minimal backend build completed${NC}"

        echo -e "\n${BLUE}🚀 Starting minimal backend services...${NC}"
        docker compose --env-file "$ENV_FILE" -f "$BACKEND_COMPOSE_FILE" up -d $services_list

        # Wait for critical services to be healthy
        echo -e "${BLUE}⏳ Waiting for minimal backend services to be healthy...${NC}"

        local max_attempts=60
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            local all_healthy=true

            # Check PostgreSQL
            if docker ps --format "{{.Names}}" | grep -q "^cptm8-postgresql$"; then
                local pg_health=$(docker inspect --format='{{.State.Health.Status}}' "cptm8-postgresql" 2>/dev/null || echo "starting")
                if [ "$pg_health" != "healthy" ]; then
                    all_healthy=false
                fi
            else
                all_healthy=false
            fi

            # Check MongoDB primary
            if docker ps --format "{{.Names}}" | grep -q "^cptm8-mongodb-1$"; then
                local mongo_health=$(docker inspect --format='{{.State.Health.Status}}' "cptm8-mongodb-1" 2>/dev/null || echo "starting")
                if [ "$mongo_health" != "healthy" ]; then
                    all_healthy=false
                fi
            else
                all_healthy=false
            fi

            # Check RabbitMQ
            if docker ps --format "{{.Names}}" | grep -q "^cptm8-rabbitmqm8$"; then
                local rabbitmq_health=$(docker inspect --format='{{.State.Health.Status}}' "cptm8-rabbitmqm8" 2>/dev/null || echo "starting")
                if [ "$rabbitmq_health" != "healthy" ]; then
                    all_healthy=false
                fi
            else
                all_healthy=false
            fi

            if [ "$all_healthy" = true ]; then
                echo -e "${GREEN}✅ Minimal backend services are healthy!${NC}"
                return 0
            fi

            echo -e "${YELLOW}⏳ Waiting for minimal backend services... ($attempt/$max_attempts)${NC}"
            sleep 10
            attempt=$((attempt + 1))
        done

        echo -e "${RED}❌ Minimal backend services failed to become healthy in time${NC}"
        echo -e "${YELLOW}⚠️  Continuing anyway, but frontend may have connection issues${NC}"
    else
        echo -e "\n${RED}❌ Minimal backend build failed${NC}"
        exit 1
    fi
}

# Function to check if backend services are running
check_backend_running() {
    echo -e "${BLUE}🔍 Checking if backend services are running...${NC}"

    # Check if backend network exists
    local network_exists=false
    if docker network ls | grep -q "cptm8_network"; then
        network_exists=true
    fi

    # Check critical backend services
    local required_services=("cptm8-postgresql" "cptm8-mongodb-1" "cptm8-rabbitmqm8")
    local missing_services=()

    for service in "${required_services[@]}"; do
        if ! docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            missing_services+=("$service")
        fi
    done

    # If network doesn't exist or services are missing, offer to start them
    if [ "$network_exists" = false ] || [ ${#missing_services[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Required backend services are not running${NC}"

        if [ ${#missing_services[@]} -ne 0 ]; then
            echo -e "${YELLOW}Missing services:${NC}"
            for service in "${missing_services[@]}"; do
                echo -e "  - $service"
            done
        fi

        echo -e "\n${BLUE}Would you like to start minimal backend services (PostgreSQL, MongoDB, RabbitMQ)?${NC}"
        echo -e "${YELLOW}[Y/n]${NC} "
        read -r response

        case "$response" in
            [nN]|[nN][oO])
                echo -e "${RED}❌ Cannot start frontend without backend services${NC}"
                echo -e "${YELLOW}💡 You can start backend manually using: $0 --backend-only${NC}"
                exit 1
                ;;
            *)
                build_minimal_backend
                return 0
                ;;
        esac
    fi

    # Check if services are healthy
    local unhealthy_services=()
    for service in "${required_services[@]}"; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "no-health-check")
        if [ "$health_status" != "healthy" ] && [ "$health_status" != "no-health-check" ]; then
            unhealthy_services+=("$service (status: $health_status)")
        fi
    done

    if [ ${#unhealthy_services[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Warning: Some backend services are not healthy yet:${NC}"
        for service in "${unhealthy_services[@]}"; do
            echo -e "  - $service"
        done
        echo -e "${YELLOW}   Frontend may experience connection issues until backend is fully healthy${NC}"
    else
        echo -e "${GREEN}✅ All required backend services are running and healthy${NC}"
    fi
}

# Function to wait for backend services
wait_for_backend() {
    echo -e "${BLUE}⏳ Waiting for backend services to be healthy...${NC}"

    local max_attempts=60
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # Check if all services with health checks are healthy
        local service_status=$(docker compose --env-file "$ENV_FILE" -f "$BACKEND_COMPOSE_FILE" ps)
        local healthy_count=$(echo "$service_status" | grep -c "(healthy)" || true)
        # Count services that have health checks (those with parentheses in status)
        local total_services_with_health=$(echo "$service_status" | grep -c "([a-z]*)" || true)

        if [ "$healthy_count" -eq "$total_services_with_health" ] && [ "$total_services_with_health" -gt 0 ]; then
            echo -e "${GREEN}✅ All backend services with health checks are healthy!${NC}"
            return 0
        fi

        echo -e "${YELLOW}⏳ Waiting for backend services... ($attempt/$max_attempts) - Healthy: $healthy_count/$total_services_with_health${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done

    echo -e "${RED}❌ Backend services failed to become healthy${NC}"
    echo -e "${BLUE}Backend service status:${NC}"
    docker compose --env-file "$ENV_FILE" -f "$BACKEND_COMPOSE_FILE" ps
    exit 1
}

# Function to build and start backend
build_backend() {
    echo -e "\n${PURPLE}📦 Backend Services${NC}"
    echo "=============================="

    local backend_cmd="docker compose --env-file $ENV_FILE -f $BACKEND_COMPOSE_FILE build $BUILD_ARGS"
    echo -e "${BLUE}Building backend: ${GREEN}$backend_cmd${NC}"

    if eval $backend_cmd; then
        echo -e "${GREEN}✅ Backend build completed${NC}"

        if [[ "$COMPOSE_ARGS" != *"--build-only"* ]]; then
            echo -e "\n${BLUE}🚀 Starting backend services...${NC}"
            docker compose --env-file "$ENV_FILE" -f "$BACKEND_COMPOSE_FILE" up -d

            # Wait for backend to be healthy
            wait_for_backend
        fi
    else
        echo -e "\n${RED}❌ Backend build failed${NC}"
        exit 1
    fi
}

# Function to build and start frontend
build_frontend() {
    echo -e "\n${PURPLE}📦 Frontend Services${NC}"
    echo "=============================="

    local frontend_cmd="docker compose --env-file $ENV_FILE -f $FRONTEND_COMPOSE_FILE build $BUILD_ARGS"
    echo -e "${BLUE}Building frontend: ${GREEN}$frontend_cmd${NC}"

    if eval $frontend_cmd; then
        echo -e "${GREEN}✅ Frontend build completed${NC}"

        if [[ "$COMPOSE_ARGS" != *"--build-only"* ]]; then
            echo -e "\n${BLUE}🚀 Starting frontend services...${NC}"
            docker compose --env-file "$ENV_FILE" -f "$FRONTEND_COMPOSE_FILE" up -d
        fi
    else
        echo -e "\n${RED}❌ Frontend build failed${NC}"
        exit 1
    fi
}

# Function to show service URLs
show_service_urls() {
    local mode=$1

    echo -e "\n${GREEN}🎉 Services are now running!${NC}"

    if [ "$mode" = "backend" ] || [ "$mode" = "both" ]; then
        echo -e "\n${BLUE}Backend Services:${NC}"
        echo -e "${BLUE}📍 PostgreSQL: ${GREEN}Internal network${NC}"
        echo -e "${BLUE}📍 MongoDB: ${GREEN}localhost:27017-27019${NC} ${YELLOW}(dev ports)${NC}"
        echo -e "${BLUE}📍 RabbitMQ: ${GREEN}http://localhost:15680${NC}"
        echo -e "${BLUE}📍 Opensearch: ${GREEN}https://localhost:9200${NC}"
        echo -e "${BLUE}📍 Opensearch Dashboard: ${GREEN}http://localhost:5601${NC}"
        echo -e "${BLUE}📍 Vector API: ${GREEN}http://localhost:8686${NC}"
        echo -e "${BLUE}📍 ASMM8 API: ${GREEN}http://localhost:8000${NC}"
        echo -e "${BLUE}📍 NaabuM8 API: ${GREEN}http://localhost:8001${NC}"
        echo -e "${BLUE}📍 KatanaM8 API: ${GREEN}http://localhost:8002${NC}"
        echo -e "${BLUE}📍 NuM8 API: ${GREEN}http://localhost:8003${NC}"
        echo -e "${BLUE}📍 ReportingM8 API: ${GREEN}http://localhost:8004${NC}"
        echo -e "${BLUE}📍 OrchestratorM8 API: ${GREEN}http://localhost:8005${NC}"
    fi

    if [ "$mode" = "frontend" ] || [ "$mode" = "both" ]; then
        echo -e "\n${BLUE}Frontend Services:${NC}"
        echo -e "${BLUE}📍 Application: ${GREEN}http://localhost:3000${NC}"
        echo -e "${BLUE}📍 Socket.IO: ${GREEN}http://localhost:4000${NC}"
    fi

    echo -e "\n${BLUE}🔍 Useful commands:${NC}"
    if [ "$mode" = "backend" ] || [ "$mode" = "both" ]; then
        echo -e "  docker compose --env-file $ENV_FILE -f $BACKEND_COMPOSE_FILE logs -f   # Backend logs"
        echo -e "  docker compose --env-file $ENV_FILE -f $BACKEND_COMPOSE_FILE ps         # Backend status"
    fi
    if [ "$mode" = "frontend" ] || [ "$mode" = "both" ]; then
        echo -e "  docker compose --env-file $ENV_FILE -f $FRONTEND_COMPOSE_FILE logs -f  # Frontend logs"
        echo -e "  docker compose --env-file $ENV_FILE -f $FRONTEND_COMPOSE_FILE ps        # Frontend status"
    fi
    echo -e "  ./build.sh stop                                                          # Stop all services"
}

# Function to execute build
execute_build() {
    case "$RUN_MODE" in
        backend)
            echo -e "${BLUE}🏗️  Building Backend Only${NC}"
            echo "=============================================="
            build_backend
            if [[ "$COMPOSE_ARGS" != *"--build-only"* ]]; then
                show_service_urls "backend"
            fi
            ;;
        frontend)
            echo -e "${BLUE}🏗️  Building Frontend Only${NC}"
            echo "=============================================="
            # Check if backend is running
            check_backend_running
            build_frontend
            if [[ "$COMPOSE_ARGS" != *"--build-only"* ]]; then
                show_service_urls "frontend"
            fi
            ;;
        both)
            echo -e "${BLUE}🏗️  Starting Two-Stage Docker Compose Build${NC}"
            echo "=============================================="

            # Stage 1: Backend Services
            echo -e "\n${PURPLE}📦 Stage 1: Backend Services${NC}"
            build_backend

            # Stage 2: Frontend Services
            echo -e "\n${PURPLE}📦 Stage 2: Frontend Services${NC}"
            build_frontend

            if [[ "$COMPOSE_ARGS" != *"--build-only"* ]]; then
                show_service_urls "both"
            fi
            ;;
        *)
            echo -e "${RED}❌ Error: Unknown run mode: $RUN_MODE${NC}"
            exit 1
            ;;
    esac
}

# Function to stop all services
stop_services() {
    echo -e "${BLUE}🛑 Stopping all services...${NC}"
    docker compose --env-file "$ENV_FILE" -f "$FRONTEND_COMPOSE_FILE" down
    docker compose --env-file "$ENV_FILE" -f "$BACKEND_COMPOSE_FILE" down
    echo -e "${GREEN}✅ All services stopped${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --no-cache)
            BUILD_ARGS="$BUILD_ARGS --no-cache"
            shift
            ;;
        --pull)
            BUILD_ARGS="$BUILD_ARGS --pull"
            shift
            ;;
        --build-only)
            COMPOSE_ARGS="$COMPOSE_ARGS --build-only"
            shift
            ;;
        --backend-only)
            RUN_MODE="backend"
            shift
            ;;
        --frontend-only)
            RUN_MODE="frontend"
            shift
            ;;
        dev|staging|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        stop)
            stop_services
            exit 0
            ;;
        --*)
            echo -e "${RED}❌ Error: Unknown option $1${NC}"
            show_usage
            exit 1
            ;;
        *)
            echo -e "${RED}❌ Error: Unknown argument $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
echo -e "${PURPLE}🐳 CPTM8 Unified Build Script${NC}"
echo -e "${PURPLE}====================================${NC}"

check_prerequisites
validate_secrets
validate_build_env
setup_environment
show_build_summary

# Confirmation for production
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${YELLOW}❓ Are you sure you want to build for PRODUCTION? (y/N)${NC}"
    read -r confirmation
    case $confirmation in
        [yY]|[yY][eE][sS])
            echo -e "${GREEN}✅ Proceeding with production build${NC}"
            ;;
        *)
            echo -e "${YELLOW}🚫 Build cancelled${NC}"
            exit 0
            ;;
    esac
fi

execute_build