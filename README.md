# CPTM8 Compose Stack - Enterprise Cybersecurity Platform

<div align="center">

**Production-ready Docker Compose orchestration for the CPTM8 microservices ecosystem.**

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)](https://www.postgresql.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?logo=mongodb)](https://www.mongodb.com/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-4.0-FF6600?logo=rabbitmq)](https://www.rabbitmq.com/)
[![Status](https://img.shields.io/badge/status-production-green)](https://github.com/deifzar/cptm8-compose-stack)

[Features](#features) • [Quick Start](#quick-start) • [Architecture](#architecture) • [Services](#services) • [Documentation](#documentation)

</div>

---

## Overview

CPTM8 Compose Stack is a production-ready Docker Compose orchestration for deploying the **CPTM8 (Cybersecurity Penetration Testing M8)** microservices ecosystem. It provides a complete, secure, and scalable infrastructure for enterprise vulnerability management and penetration testing operations.

**What's Included:**
- **Frontend Services**: DashboardM8 (Next.js) + SocketM8 (real-time server)
- **Backend Services**: 6 specialized security scanner microservices
- **Infrastructure**: PostgreSQL, MongoDB replica set, RabbitMQ, OpenSearch cluster
- **Monitoring & Logging**: Vector log aggregator + OpenSearch Dashboards
- **Security**: Docker secrets, multi-stage builds, non-root containers

---

## Features

### 🏗️ **Two-Tier Microservices Architecture**
- **Frontend Tier**: Web dashboard + real-time WebSocket server
- **Backend Tier**: Databases, message queue, scanner services, monitoring

### 🔐 **Enterprise-Grade Security**
- Docker secrets for sensitive credentials (17 secret files)
- Multi-stage builds preventing secret leakage
- Non-root container execution
- Minimal Alpine Linux base images
- Hardened security configurations

### 🚀 **Intelligent Build System**
- Environment-aware build script (dev/staging/production)
- Two-stage sequential deployment (backend → frontend)
- Flexible build modes (backend-only, frontend-only, complete)
- Automatic health checks and dependency validation
- Interactive production confirmations

### 📊 **Comprehensive Monitoring**
- OpenSearch 2-node cluster for log aggregation
- Vector log pipeline for structured logging
- OpenSearch Dashboards for visualization
- Service health checks and restart policies

### 🔄 **Real-Time Communication**
- RabbitMQ message queue with topic exchanges
- Socket.IO for live dashboard updates
- Async notification delivery

### 🗄️ **Dual Database Architecture**
- PostgreSQL 15 for operational data
- MongoDB 7.x (3-node replica set) for NoSQL/chat data
- Optimized indexing and connection pooling

---

## Quick Start

### Prerequisites

- **Docker** 20.10+ with Docker Compose v2
- **Git** (for cloning the repository)
- **Linux/macOS** (tested on Ubuntu 20.04+, macOS 12+)
- **Minimum Resources**: 8GB RAM, 4 CPU cores, 50GB storage

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/deifzar/cptm8-compose-stack.git
cd cptm8-compose-stack
```

#### 2. Configure Environment Files

**Create `.env` file:**
```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

**Create `.env.build` file:**
```bash
cp .env.build.example .env.build
# Add database URLs for Prisma generation
nano .env.build
```

**Required `.env` variables:**
```bash
NODE_ENV=production
DASHBOARDM8_PORT=3000
SOCKETM8_PORT=4000
POSTGRESQL_POSTGRES_USER=cpt_dbuser
POSTGRESQL_POSTGRES_DB=cptm8
SMTP_SERVER=email-smtp.your-region.amazonaws.com
SMTP_PORT=587
SMTP_EMAILSENDER=noreply@yourcompany.com
CLOUD_PROVIDER=AWS
RabbitMQ_EXCHANGE=notification
USER_EMAIL_DOMAIN=yourcompany.com
```

**Required `.env.build` variables:**
```bash
PPG_DATABASE_URL="postgresql://cpt_dbuser:yourpassword@postgresqlm8:5432/cptm8"
PMG_DATABASE_URL="mongodb://cpt_dbuser:yourpassword@mongodb-1:27017/cptm8?authSource=cptm8&replicaSet=rs0"
```

#### 3. Create Secret Files

**All secrets must be created in the `secrets/` directory:**

```bash
# PostgreSQL secrets
echo "your-postgres-root-password" > secrets/postgresql_root_password.txt
echo "your-postgres-user-password" > secrets/postgresql_user_password.txt
echo "postgresql://cpt_dbuser:yourpassword@postgresqlm8:5432/cptm8" > secrets/postgresql_database_url.txt

# MongoDB secrets
echo "your-mongodb-root-password" > secrets/mongodb_root_password.txt
echo "your-mongodb-user-password" > secrets/mongodb_user_password.txt
echo "mongodb://cpt_dbuser:yourpassword@mongodb-1:27017/cptm8?authSource=cptm8&replicaSet=rs0" > secrets/mongodb_database_url.txt

# RabbitMQ secrets
echo "your-rabbitmq-username" > secrets/rabbitmq_username.txt
echo "your-rabbitmq-password" > secrets/rabbitmq_password.txt
echo "amqp://your-rabbitmq-username:your-rabbitmq-password@rabbitmqm8:5672/" > secrets/rabbitmq_url.txt

# OpenSearch secrets
echo "your-opensearch-admin-password" > secrets/opensearch_admin_password.txt

# Application secrets
echo "your-random-32-char-jwt-secret" > secrets/auth_secret.txt

# OAuth secrets (Google)
echo "your-google-client-id" > secrets/google_client_id.txt
echo "your-google-client-secret" > secrets/google_client_secret.txt

# SMTP secrets
echo "your-smtp-username" > secrets/smtp_username.txt
echo "your-smtp-password" > secrets/smtp_password.txt

# AWS secrets (for S3 report storage)
echo "your-aws-access-key-id" > secrets/aws_key.txt
echo "your-aws-secret-access-key" > secrets/aws_secret.txt

# Set proper permissions
chmod 600 secrets/*.txt
```

**⚠️ Important:** Replace all `your-*` placeholders with actual secure values.

#### 4. Build and Deploy

**Development Environment:**
```bash
./build.sh
# or explicitly
./build.sh dev
```

**Production Environment:**
```bash
./build.sh prod
```

**Other Build Options:**
```bash
# Backend services only
./build.sh --backend-only

# Frontend services only (auto-starts minimal backend if needed)
./build.sh --frontend-only

# Force rebuild without cache
./build.sh prod --no-cache --pull

# Build without starting services
./build.sh --build-only
```

#### 5. Verify Deployment

**Check service status:**
```bash
docker compose -f docker-compose-backend.yml ps
docker compose -f docker-compose-frontend.yml ps
```

**Access the application:**
- **DashboardM8**: http://localhost:3000
- **SocketM8**: http://localhost:4000
- **RabbitMQ Management**: http://localhost:15680
- **OpenSearch**: https://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601

---

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend Tier                            │
│  ┌──────────────┐              ┌──────────────┐             │
│  │ DashboardM8  │──────────────▶│   SocketM8   │             │
│  │  (Next.js)   │  HTTP/REST   │  (Socket.IO) │             │
│  │  Port 3000   │              │  Port 4000   │             │
│  └──────────────┘              └──────────────┘             │
│         │                             │                      │
└─────────┼─────────────────────────────┼──────────────────────┘
          │                             │
    ┌─────▼─────────────────────────────▼──────┐
    │     Docker Network (cptm8_network)       │
    │          172.25.0.0/16                   │
    └─────┬────────────────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────────────┐
│                    Backend Tier                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Infrastructure Services                  │    │
│  │                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │    │
│  │  │ PostgreSQL   │  │  MongoDB     │  │ RabbitMQ │ │    │
│  │  │  (Primary)   │  │(Replica Set) │  │(Messages)│ │    │
│  │  │ 172.25.0.6   │  │ 172.25.0.7-9 │  │          │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────┘ │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Scanner Services (Go)                    │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │    │
│  │  │Orchestrator │  │    ASMM8    │  │  NaabuM8   │ │    │
│  │  │   (8005)    │  │   (8000)    │  │   (8001)   │ │    │
│  │  │Coordination │  │Asset Disc.  │  │Port Scan   │ │    │
│  │  └─────────────┘  └─────────────┘  └────────────┘ │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │    │
│  │  │  KatanaM8   │  │    NuM8     │  │ ReportingM8│ │    │
│  │  │   (8002)    │  │   (8003)    │  │   (8004)   │ │    │
│  │  │Web Crawler  │  │Vuln Scanner │  │Report Gen. │ │    │
│  │  └─────────────┘  └─────────────┘  └────────────┘ │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │        Monitoring & Logging                        │    │
│  │                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │    │
│  │  │ OpenSearch-1 │  │ OpenSearch-2 │  │  Vector  │ │    │
│  │  │   (9200)     │  │   (Cluster)  │  │  (8686)  │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────┘ │    │
│  │                                                      │    │
│  │  ┌──────────────┐                                   │    │
│  │  │ OpenSearch   │                                   │    │
│  │  │  Dashboard   │                                   │    │
│  │  │   (5601)     │                                   │    │
│  │  └──────────────┘                                   │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. User interacts with DashboardM8 (Next.js dashboard)
2. DashboardM8 sends scan requests to backend services
3. OrchestratorM8 coordinates the scanning workflow:
   ├─→ ASMM8: Subdomain enumeration (Subfinder, DNSx, Alterx)
   ├─→ NaabuM8: Port scanning (Nmap)
   ├─→ KatanaM8: Endpoint discovery (web crawling)
   └─→ NuM8: Vulnerability detection (Nuclei)
4. Scanner services store results in PostgreSQL
5. ReportingM8 generates reports and sends emails (SMTP) or stores in S3
6. RabbitMQ publishes notifications to SocketM8
7. SocketM8 pushes real-time updates to DashboardM8 (WebSocket)
8. All logs flow to Vector → OpenSearch for centralized monitoring
```

---

## Services

### Frontend Services

| Service | Port | Description | Technology |
|---------|------|-------------|------------|
| **DashboardM8** | 3000 | Web dashboard for vulnerability management | Next.js 15, React 19, TypeScript |
| **SocketM8** | 4000 | Real-time WebSocket server for notifications | Socket.IO, Express |

**Note:** DashboardM8 and SocketM8 are **proprietary services** and are **not included** in this public repository. See [Getting Access](#getting-access-to-proprietary-services) below.

### Backend Scanner Services

| Service | Port | Description | Technology |
|---------|------|-------------|------------|
| **OrchestratorM8** | 8005 | Task coordination and workflow orchestration | Go binary |
| **ASMM8** | 8000 | Asset discovery: subdomain enumeration, DNS | Go + Subfinder + DNSx |
| **NaabuM8** | 8001 | Network port scanning and service detection | Go + Nmap |
| **KatanaM8** | 8002 | HTTP endpoint discovery and web crawling | Go + Katana |
| **NuM8** | 8003 | Vulnerability scanning and detection | Go + Nuclei |
| **ReportingM8** | 8004 | Security report generation (PDF/email/S3) | Go + SMTP + AWS SDK |

**Note:** Scanner service binaries are **not included** in this repository. Contact for access.

### Infrastructure Services

| Service | Port(s) | Description | Technology |
|---------|---------|-------------|------------|
| **PostgreSQL** | 5432 | Primary operational database | PostgreSQL 15 |
| **MongoDB** | 27017-27019 | NoSQL database (3-node replica set) | MongoDB 7.x |
| **RabbitMQ** | 5672, 15672 | Message queue for async operations | RabbitMQ 4.0.3 |
| **OpenSearch** | 9200 | Distributed search and analytics (2-node cluster) | OpenSearch 2.x |
| **OpenSearch Dashboards** | 5601 | Log visualization and monitoring | OpenSearch Dashboards |
| **Vector** | 8686 | Log aggregation and forwarding | Vector 0.41.1 |

---

## Build System

### Build Script: `./build.sh`

The `build.sh` script provides intelligent, environment-aware building with comprehensive validation.

#### Basic Usage

```bash
./build.sh [environment] [options]
```

#### Environments

- `dev` - Development environment (default)
- `staging` - Staging environment
- `prod` - Production environment (requires confirmation)

#### Options

- `--backend-only` - Build and run only backend services
- `--frontend-only` - Build and run only frontend services (auto-starts minimal backend)
- `--no-cache` - Force rebuild without Docker cache
- `--pull` - Pull latest base images before building
- `--build-only` - Build services without starting them
- `--help` or `-h` - Show help message

#### Commands

- `stop` - Stop all running services

#### Examples

```bash
# Development two-stage build (default)
./build.sh

# Production build (with confirmation prompt)
./build.sh prod

# Staging build with fresh images
./build.sh staging --no-cache --pull

# Backend only (databases + scanners + monitoring)
./build.sh --backend-only

# Frontend only (prompts to start minimal backend if needed)
./build.sh --frontend-only

# Build without starting
./build.sh dev --build-only

# Stop all services
./build.sh stop
```

### Build Strategy

**Default Two-Stage Sequential Build:**

1. **Stage 1: Backend Services**
   - Build all backend services
   - Start services
   - Wait for health checks to pass (PostgreSQL, MongoDB, RabbitMQ)
   - Verify all services are healthy

2. **Stage 2: Frontend Services**
   - Build frontend services
   - Start services
   - Services automatically connect to backend

**Frontend-Only Mode:**
- Checks if backend is running
- If not, prompts to start minimal backend (PostgreSQL, MongoDB, RabbitMQ)
- Waits for minimal backend health checks
- Starts frontend services

### Build Script Features

✅ **Prerequisite Validation**
- Checks Docker and Docker Compose installation
- Verifies compose files exist
- Validates environment files

✅ **Secret Validation**
- Ensures all 17 required secret files exist
- Warns about placeholder values
- Validates build environment (`.env.build`)

✅ **Health Checks**
- Monitors service health status
- Waits for services to be ready (max 60 attempts)
- Provides real-time health status updates

✅ **Interactive Confirmations**
- Production builds require explicit confirmation
- Frontend-only mode offers to start minimal backend

✅ **Environment-Specific Settings**
- Development: `--pull`
- Staging: `--pull --no-cache`
- Production: `--pull --no-cache` + warnings about dev ports

---

## Configuration

### Environment Variables

#### `.env` - Non-Sensitive Configuration

```bash
# Application
NODE_ENV=production
DASHBOARDM8_PORT=3000
SOCKETM8_PORT=4000

# Database (non-sensitive)
POSTGRESQL_POSTGRES_USER=cpt_dbuser
POSTGRESQL_POSTGRES_DB=cptm8
MONGO_INITDB_ROOT_USERNAME=cpt_dbuser
MONGO_NON_ROOT_USERNAME=cpt_dbuser
MONGO_INITDB_DATABASE=cptm8
MONGO_INITDB_COLLECTION=support

# SMTP (non-sensitive)
SMTP_SERVER=email-smtp.eu-north-1.amazonaws.com
SMTP_PORT=587
SMTP_EMAILSENDER=noreply@yourcompany.com

# Other
CLOUD_PROVIDER=AWS
RabbitMQ_EXCHANGE=notification
USER_EMAIL_DOMAIN=yourcompany.com
NEXT_BASE_URL=http://localhost:3000
NEXT_PUBLIC_SOCKET_SERVER=http://localhost:4000
```

#### `.env.build` - Build-Time Secrets

Used during Docker build for Prisma client generation:

```bash
PPG_DATABASE_URL="postgresql://cpt_dbuser:password@postgresqlm8:5432/cptm8"
PMG_DATABASE_URL="mongodb://cpt_dbuser:password@mongodb-1:27017/cptm8?authSource=cptm8&replicaSet=rs0"
```

### Docker Secrets

All sensitive credentials are stored in `secrets/*.txt` files and mounted to `/run/secrets/` in containers:

**Required Secrets (17 files):**

```
secrets/
├── auth_secret.txt                    # JWT signing secret
├── aws_key.txt                        # AWS access key ID
├── aws_secret.txt                     # AWS secret access key
├── google_client_id.txt               # Google OAuth client ID
├── google_client_secret.txt           # Google OAuth client secret
├── mongodb_database_url.txt           # MongoDB connection string
├── mongodb_root_password.txt          # MongoDB root password
├── mongodb_user_password.txt          # MongoDB user password
├── opensearch_admin_password.txt      # OpenSearch admin password
├── postgresql_database_url.txt        # PostgreSQL connection string
├── postgresql_root_password.txt       # PostgreSQL postgres user password
├── postgresql_user_password.txt       # PostgreSQL app user password
├── rabbitmq_password.txt              # RabbitMQ password
├── rabbitmq_url.txt                   # RabbitMQ connection URL
├── rabbitmq_username.txt              # RabbitMQ username
├── smtp_password.txt                  # SMTP password
└── smtp_username.txt                  # SMTP username
```

**Security Best Practices:**
- Use strong, randomly generated passwords (32+ characters)
- Use unique secrets per environment (dev/staging/production)
- Set file permissions: `chmod 600 secrets/*.txt`
- Never commit secret files to version control (.gitignore configured)
- Rotate secrets regularly (every 90 days recommended)

---

## Database Setup

### PostgreSQL Schema

The PostgreSQL database contains operational data for the CPTM8 platform.

**Core Tables:**

```sql
-- Root domains to scan
CREATE TABLE cptm8domain (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL UNIQUE,
    companyname VARCHAR(50),
    enabled BOOLEAN DEFAULT true
);

-- Discovered subdomains
CREATE TABLE cptm8hostname (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL UNIQUE,
    foundfirsttime TIMESTAMPTZ NOT NULL,
    live BOOLEAN,
    enabled BOOLEAN DEFAULT true,
    domainid UUID REFERENCES cptm8domain(id) ON DELETE CASCADE
);

-- HTTP endpoints on hostnames
CREATE TABLE cptm8endpoint (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    endpoint VARCHAR(255) NOT NULL UNIQUE,
    live BOOLEAN,
    hostnameid UUID REFERENCES cptm8hostname(id) ON DELETE CASCADE
);

-- Network services
CREATE TABLE cptm8service (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    port INT NOT NULL,
    protocol VARCHAR(10),
    service_name VARCHAR(100),
    hostnameid UUID REFERENCES cptm8hostname(id) ON DELETE CASCADE
);

-- Security vulnerabilities
CREATE TABLE cptm8vulnerability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    cvss_score DECIMAL(3,1),
    risk_level VARCHAR(50),
    status VARCHAR(20),
    endpointid UUID REFERENCES cptm8endpoint(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users and authentication
CREATE TABLE "User" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255),
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_hostname_domain ON cptm8hostname(domainid);
CREATE INDEX idx_hostname_live ON cptm8hostname(live);
CREATE INDEX idx_endpoint_hostname ON cptm8endpoint(hostnameid);
CREATE INDEX idx_vulnerability_endpoint ON cptm8vulnerability(endpointid);
CREATE INDEX idx_service_hostname ON cptm8service(hostnameid);
```

**Database Initialization:**

The `services/postgresqlm8/init0.sh` and `init1.sql` scripts automatically:
1. Enable UUID extension
2. Create application user (`cpt_dbuser`)
3. Create database (`cptm8`)
4. Grant appropriate permissions

### MongoDB Setup

MongoDB is used for real-time messaging and chat functionality.

**Collections:**
- `support` - Chat/support messages

**Replica Set Configuration:**

The MongoDB setup uses a 3-node replica set (`rs0`) for high availability:
- `mongodb-1` - Primary node (172.25.0.7)
- `mongodb-2` - Secondary node (172.25.0.8)
- `mongodb-3` - Secondary node (172.25.0.9)

The `mongodb-init` service automatically initializes the replica set on first startup.

---

## Usage

### Managing Services

**Start all services:**
```bash
./build.sh prod
```

**Stop all services:**
```bash
./build.sh stop
```

**View logs:**
```bash
# Backend logs
docker compose -f docker-compose-backend.yml logs -f

# Frontend logs
docker compose -f docker-compose-frontend.yml logs -f

# Specific service
docker compose -f docker-compose-backend.yml logs -f postgresqlm8
```

**Check service status:**
```bash
# Backend status
docker compose -f docker-compose-backend.yml ps

# Frontend status
docker compose -f docker-compose-frontend.yml ps
```

**Restart a service:**
```bash
docker compose -f docker-compose-backend.yml restart postgresqlm8
```

### Accessing Services

**Database Access:**

```bash
# PostgreSQL shell
docker compose -f docker-compose-backend.yml exec postgresqlm8 psql -U cpt_dbuser -d cptm8

# MongoDB shell (primary)
docker compose -f docker-compose-backend.yml exec mongodb-1 mongosh -u cpt_dbuser -p

# Check MongoDB replica set status
docker compose -f docker-compose-backend.yml exec mongodb-1 mongosh --eval "rs.status()"
```

**RabbitMQ Management:**
- URL: http://localhost:15680
- Default credentials configured in secrets

**OpenSearch:**
- URL: https://localhost:9200
- OpenSearch Dashboards: http://localhost:5601
- Default credentials configured in secrets

**Scanner APIs:**
- ASMM8: http://localhost:8000/health
- NaabuM8: http://localhost:8001/health
- KatanaM8: http://localhost:8002/health
- NuM8: http://localhost:8003/health
- ReportingM8: http://localhost:8004/health
- OrchestratorM8: http://localhost:8005/health

---

## Security Considerations

### Container Security

✅ **Implemented Security Features:**
- Multi-stage Docker builds (secrets never in final images)
- Non-root user execution in all containers
- Minimal Alpine Linux base images
- Read-only root filesystems (where possible)
- Dropped Linux capabilities
- Docker secrets for sensitive data
- Health checks for all services
- Restart policies (`on-failure:3`)

### Network Security

- Internal bridge network (`cptm8_network`, 172.25.0.0/16)
- Services communicate via Docker DNS
- Static IPs for databases ensure predictable connections
- Only necessary ports exposed to host

### Production Deployment Checklist

Before deploying to production:

- [ ] **Remove development database ports** from docker-compose files
  - PostgreSQL port 5442
  - MongoDB ports 27017-27019

- [ ] **Update all secrets** with production values (no placeholders)

- [ ] **Rotate secrets** regularly (every 90 days recommended)

- [ ] **Use unique secrets** per environment

- [ ] **Set proper file permissions**:
  ```bash
  chmod 600 secrets/*.txt
  chmod 640 .env .env.build
  ```

- [ ] **Configure external firewall rules**

- [ ] **Enable TLS/HTTPS**:
  - Configure reverse proxy (nginx/Traefik)
  - Obtain SSL certificates (Let's Encrypt)
  - Update `NEXT_BASE_URL` to use HTTPS

- [ ] **Configure proper SMTP settings** for production email delivery

- [ ] **Set up AWS S3 bucket** for report storage

- [ ] **Configure OAuth apps** for production domains

- [ ] **Review and set appropriate resource limits** in docker-compose files

- [ ] **Set up external backup strategy** for databases

- [ ] **Configure monitoring and alerting** (e.g., Prometheus, Grafana)

- [ ] **Review logs** regularly in OpenSearch Dashboards

### Secret Handling Rules

**DO:**
- ✅ Store secrets in separate `secrets/*.txt` files
- ✅ Use strong, randomly generated values
- ✅ Use environment variables for non-sensitive config
- ✅ Mount secrets to `/run/secrets/` in containers
- ✅ Read secrets using `*_FILE` environment variables in apps

**DON'T:**
- ❌ Put secrets in docker-compose.yml directly
- ❌ Commit secret files to version control
- ❌ Use the same secrets across environments
- ❌ Log secret values in application logs
- ❌ Share secrets via insecure channels

---

## Troubleshooting

### Common Issues

#### 1. Build Fails - Missing Secrets

**Symptom:**
```bash
❌ Error: Missing required secret files
```

**Solution:**
```bash
# Ensure all 17 secret files exist
ls -la secrets/

# Create missing secret files
echo "your-value" > secrets/missing_secret.txt
chmod 600 secrets/missing_secret.txt
```

#### 2. Database Connection Failures

**Symptom:**
```
ECONNREFUSED postgresql:5432
```

**Solution:**
```bash
# Check PostgreSQL is running and healthy
docker compose -f docker-compose-backend.yml ps postgresqlm8

# View PostgreSQL logs
docker compose -f docker-compose-backend.yml logs postgresqlm8

# Check health manually
docker compose -f docker-compose-backend.yml exec postgresqlm8 pg_isready -U cpt_dbuser

# Verify connection string in secrets
cat secrets/postgresql_database_url.txt
```

#### 3. MongoDB Replica Set Not Initialized

**Symptom:**
```
MongoServerError: not master and slaveOk=false
```

**Solution:**
```bash
# Check MongoDB replica set status
docker compose -f docker-compose-backend.yml exec mongodb-1 mongosh --eval "rs.status()"

# Re-initialize replica set (if needed)
docker compose -f docker-compose-backend.yml restart mongodb-init

# Wait for initialization to complete (check logs)
docker compose -f docker-compose-backend.yml logs -f mongodb-init
```

#### 4. RabbitMQ Connection Errors

**Symptom:**
```
ECONNREFUSED rabbitmqm8:5672
```

**Solution:**
```bash
# Check RabbitMQ status
docker compose -f docker-compose-backend.yml ps rabbitmqm8

# Check health
docker compose -f docker-compose-backend.yml exec rabbitmqm8 rabbitmq-diagnostics ping

# View RabbitMQ logs
docker compose -f docker-compose-backend.yml logs rabbitmqm8

# Access management UI
open http://localhost:15680
```

#### 5. Frontend Can't Connect to Backend

**Symptom:**
```
Error: Cannot connect to backend services
```

**Solution:**
```bash
# Ensure backend is running
docker compose -f docker-compose-backend.yml ps

# Check if minimal backend services are healthy
docker inspect --format='{{.State.Health.Status}}' cptm8-postgresql
docker inspect --format='{{.State.Health.Status}}' cptm8-mongodb-1
docker inspect --format='{{.State.Health.Status}}' cptm8-rabbitmqm8

# Verify network exists
docker network ls | grep cptm8_network

# Check frontend can reach backend
docker compose -f docker-compose-frontend.yml exec dashboardm8 ping postgresql
```

#### 6. OpenSearch Cluster Unhealthy

**Symptom:**
```
Cluster status: RED
```

**Solution:**
```bash
# Check OpenSearch cluster health
curl -k -u admin:$(cat secrets/opensearch_admin_password.txt) https://localhost:9200/_cluster/health?pretty

# View OpenSearch logs
docker compose -f docker-compose-backend.yml logs opensearch-node1

# Check disk space
df -h

# Restart OpenSearch cluster
docker compose -f docker-compose-backend.yml restart opensearch-node1 opensearch-node2
```

#### 7. Build Script Permission Denied

**Symptom:**
```bash
bash: ./build.sh: Permission denied
```

**Solution:**
```bash
chmod +x build.sh
./build.sh
```

#### 8. Port Already in Use

**Symptom:**
```
Error: bind: address already in use
```

**Solution:**
```bash
# Find process using the port
lsof -i :3000  # Replace with the conflicting port

# Stop the conflicting service or change port in .env
```

### Debug Commands

**Check all service health:**
```bash
# Backend services
for service in postgresqlm8 mongodb-1 mongodb-2 mongodb-3 rabbitmqm8 opensearch-node1 opensearch-node2; do
  echo "Checking $service..."
  docker inspect --format='{{.State.Health.Status}}' cptm8-$service 2>/dev/null || echo "No health check"
done
```

**View all logs:**
```bash
# Last 100 lines from all services
docker compose -f docker-compose-backend.yml logs --tail=100
docker compose -f docker-compose-frontend.yml logs --tail=100
```

**Check Docker network:**
```bash
# Inspect network
docker network inspect cptm8_network

# List containers in network
docker network inspect cptm8_network --format='{{range .Containers}}{{.Name}} {{end}}'
```

**Check volumes:**
```bash
# List CPTM8 volumes
docker volume ls | grep cptm8

# Inspect volume
docker volume inspect cptm8_postgresql_data
```

---

## Performance Optimization

### Resource Allocation

**Recommended Minimum:**
- CPU: 4 cores
- RAM: 8 GB
- Storage: 50 GB

**Recommended Production:**
- CPU: 8+ cores
- RAM: 16+ GB
- Storage: 200+ GB (with monitoring enabled)

### Database Optimization

**PostgreSQL:**
- Indexes already configured for common queries
- Connection pooling via Prisma
- Adjust `max_connections` and `shared_buffers` in `postgresql.conf` if needed

**MongoDB:**
- Replica set for high availability
- Indexes on frequently queried fields
- OpLog sizing automatically managed

### Scaling Considerations

**Horizontal Scaling:**
- Scanner services can be scaled horizontally:
  ```bash
  docker compose -f docker-compose-backend.yml up -d --scale asmm8=3
  ```

**Vertical Scaling:**
- Adjust resource limits in docker-compose files:
  ```yaml
  services:
    postgresqlm8:
      deploy:
        resources:
          limits:
            cpus: '2'
            memory: 4G
  ```

---

## Documentation

### Additional Documentation

- **[docs/README-SECURE-SETUP.md](docs/README-SECURE-SETUP.md)** - Comprehensive security setup guide
  - Secret management best practices
  - Build-time vs runtime secrets
  - Production security checklist
  - Migration guide

### Service-Specific Documentation

**Frontend Services:**
- [services/dashboardm8/README.md](services/dashboardm8/README.md) - DashboardM8 documentation
- [services/socketm8/README.md](services/socketm8/README.md) - SocketM8 documentation

**Scanner Services:**
Documentation provided separately with service binaries.

---

## Getting Access to Proprietary Services

### DashboardM8 & SocketM8 (Frontend)

DashboardM8 and SocketM8 are **proprietary services** and are **not included** in this public repository.

**What's Included in the Proprietary Package:**
- Complete Next.js 15 + React 19 dashboard source code
- Socket.IO real-time server implementation
- Full authentication system (NextAuth.js + OAuth)
- Dual Prisma client setup (PostgreSQL + MongoDB)
- Rich text editor integration (TipTap)
- Data visualization components (ApexCharts)
- Production-ready Docker configurations
- Comprehensive documentation

### Scanner Service Binaries

The backend scanner services (ASMM8, NaabuM8, KatanaM8, NuM8, ReportingM8, OrchestratorM8) are **Go binaries** that are **not included** in this repository.

### Request Access

This repository provides the **infrastructure orchestration** for the CPTM8 platform. The proprietary application services are available through:
- **Subscription licensing**
- **Contract-based agreements**
- **Custom enterprise deployments**

**Interested in the complete CPTM8 platform?**

If you're interested in:
- Accessing the complete DashboardM8 and SocketM8 source code
- Obtaining scanner service binaries
- Seeing a live demo of the platform
- Learning about pricing and licensing
- Discussing custom enterprise deployments
- Partnering on security research

**Get in touch:**

📧 **Email:** [Your email here]
💼 **LinkedIn:** [Your LinkedIn profile]
🌐 **Website:** [Your website]
📦 **GitHub:** [https://github.com/deifzar/cptm8-compose-stack](https://github.com/deifzar/cptm8-compose-stack)

---

## Contributing

### Contributing to Infrastructure

Contributions to the infrastructure and orchestration are welcome!

**How to Contribute:**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test thoroughly in all environments (dev/staging/prod)
5. Commit your changes (`git commit -m 'Add infrastructure improvement'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Open a Pull Request

**Areas for Contribution:**
- Docker Compose optimizations
- Build script improvements
- Documentation enhancements
- Security hardening
- Performance tuning
- Additional environment support

### Code Quality Standards

- Follow existing patterns and conventions
- Test in all three environments (dev/staging/prod)
- Update documentation for any changes
- Include comments for complex configurations
- Validate with `docker compose config` before committing

---

## License

**CPTM8 Compose Stack** is open source infrastructure orchestration.

**Proprietary Components:**
- DashboardM8 (Next.js dashboard)
- SocketM8 (Socket.IO server)
- Scanner service binaries (Go)

These proprietary components are **not included** in this repository and are available through separate licensing agreements.

---

## Acknowledgments

- [Docker](https://www.docker.com/) for containerization platform
- [PostgreSQL](https://www.postgresql.org/) for reliable relational database
- [MongoDB](https://www.mongodb.com/) for flexible NoSQL database
- [RabbitMQ](https://www.rabbitmq.com/) for robust message queuing
- [OpenSearch](https://opensearch.org/) for powerful search and analytics
- [Vector](https://vector.dev/) for efficient log aggregation
- [Alpine Linux](https://alpinelinux.org/) for minimal base images

---

<div align="center">

**CPTM8 Compose Stack** - Enterprise Cybersecurity Platform Orchestration

Built with ❤️ for the security community

[⬆ Back to Top](#cptm8-compose-stack---enterprise-cybersecurity-platform)

</div>
