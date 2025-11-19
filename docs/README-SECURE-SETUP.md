# 🔐 Secure DashboardM8 Docker Setup Guide

## Overview

This setup provides a **production-ready, secure Docker Compose configuration** for the DashboardM8 cybersecurity vulnerability management dashboard. It implements industry best practices for secrets management, avoiding secret leakage in Docker images and logs.

## 🛡️ Security Features

### ✅ **What We've Secured:**
- **Docker Secrets**: All sensitive data handled via Docker secrets (not environment variables)
- **No Secret Leakage**: Secrets never appear in Docker images, layers, or container environment
- **Build-time Security**: Database URLs securely mounted during Prisma generation
- **Layered Security**: Three-tier secret management (build/runtime/environment)
- **Git Safety**: Comprehensive .gitignore prevents accidental secret commits

### ✅ **Security Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                   Secret Management                         │
├─────────────────────────────────────────────────────────────┤
│  Build Time: Secret mount for Prisma generation            │
│  Runtime: Docker secrets mounted to /run/secrets/          │
│  Environment: Non-sensitive config via .env.compose        │
└─────────────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
DashboardM8/Docker/
├── docker-compose.yml          # Unified compose with secrets
├── .env                       # Non-sensitive environment variables
├── .env.build                 # Build-time database URLs only (sensitive)
├── build.sh                   # Secure build script
├── .gitignore                 # Prevents secret leakage
├── secrets/                   # Secret files directory (sensitive)
│   ├── .gitkeep              # Keeps directory in git
│   ├── postgresql_password.txt
│   ├── postgresql_database_url.txt
│   ├── mongodb_root_password.txt
│   ├── mongodb_user_password.txt
│   ├── mongodb_database_url.txt
│   ├── auth_secret.txt
│   ├── google_client_id.txt
│   ├── google_client_secret.txt
│   ├── smtp_username.txt
│   ├── smtp_password.txt
│   ├── aws_key.txt
│   └── aws_secret.txt
└── services/
    ├── dashboardm8/           # Next.js application
    ├── postgresqlm8/          # PostgreSQL database
    └── mongodbm8/             # MongoDB replica set
```

## 🚀 Quick Start

### 1. **Update Secret Files**
```bash
# Navigate to the secrets directory
cd secrets/

# Update each secret file with your real values
echo "your-real-postgresql-password" > postgresql_password.txt
echo "your-real-mongodb-password" > mongodb_root_password.txt
echo "your-auth-secret" > auth_secret.txt
echo "your-google-client-id" > google_client_id.txt
# ... update all secret files
```

### 2. **Update Environment Configuration**
```bash
# Edit .env.compose for non-sensitive settings
vim .env

# Update .env.build with your database connection details (sensitive)
vim .env.build
```

### 3. **Build and Run**
```bash
# Development build
./build.sh

# Production build
./build.sh production

# Build with specific options
./build.sh production --no-cache --pull
```

## 🔧 Detailed Setup

### **Environment Files Explained**

#### `.env` - Non-Sensitive Configuration
Contains database usernames, server settings, and other non-sensitive config that can be version controlled.

```bash
POSTGRESQL_POSTGRES_USER=cpt_dbuser
POSTGRESQL_POSTGRES_DB=cptm8
SMTP_SERVER=smtp.gmail.com
NEXT_BASE_URL=http://localhost:3000
```

#### `.env.build` - Build-time Database URLs
**ONLY contains database URLs needed for Prisma client generation.**
```bash
PPG_DATABASE_URL="postgresql://user:pass@postgresql:5432/db"
PMG_DATABASE_URL="mongodb://user:pass@mongodb-1:27017/db"
```

#### `secrets/*.txt` - Sensitive Values
Each secret in its own file, mounted as Docker secrets:
```bash
secrets/postgresql_password.txt         # Database passwords
secrets/auth_secret.txt                 # JWT signing secret
secrets/google_client_secret.txt        # OAuth secrets
secrets/smtp_password.txt               # Email credentials
```

### **How Secrets Flow Through the System**

#### 1. **Build Time (Prisma Generation)**
```dockerfile
# Dockerfile uses secret mount for database URLs
RUN --mount=type=secret,id=build_database_urls,target=/app/.env \
    npx prisma generate --schema ./prisma/prisma-postgresql/schema.prisma
```

#### 2. **Runtime (Application)**
```yaml
# docker-compose.yml mounts secrets to /run/secrets/
environment:
  PPG_DATABASE_URL_FILE: /run/secrets/postgresql_database_url
  AUTH_SECRET_FILE: /run/secrets/auth_secret
secrets:
  - postgresql_database_url
  - auth_secret
```

#### 3. **Application Code**
Your Next.js app should read secrets directly from environment variables.


## 🛠️ Build Script Usage

The `build.sh` script provides secure, environment-aware building:

```bash
# Basic usage
./build.sh [environment] [options]

# Examples
./build.sh                          # Development build
./build.sh production               # Production build  
./build.sh staging --no-cache      # Staging with fresh build
./build.sh production --build-only  # Build without starting
```

### **Build Script Features:**
- ✅ **Prerequisite Validation**: Checks Docker, Compose, files
- ✅ **Secret Validation**: Ensures required secrets exist
- ✅ **Environment Setup**: Configures build for dev/staging/prod
- ✅ **Security Warnings**: Alerts about placeholder values
- ✅ **Interactive Confirmation**: Requires confirmation for production

## 🔒 Security Best Practices

### **✅ DO:**
- Store secrets in separate `secrets/*.txt` files
- Use unique, strong passwords and keys
- Rotate secrets regularly
- Use different secrets for different environments
- Review `.gitignore` to ensure no secrets are committed
- Use the `_FILE` environment variable pattern in your app

### **❌ DON'T:**
- Put secrets directly in docker-compose.yml
- Use environment variables for sensitive data
- Commit secret files to version control
- Use the same secrets across environments
- Log secret values in application logs

### **Secret File Permissions:**
```bash
# Restrict access to secret files
chmod 600 secrets/*.txt
chown root:root secrets/*.txt  # In production
```

## 🚨 Production Deployment

### **Before Production:**

1. **Remove Development Ports:**
```yaml
# Remove these from docker-compose.yml
ports:
  - "27017:27017"  # MongoDB
  - "27018:27017"  # MongoDB
  - "27019:27017"  # MongoDB
```

2. **Update Network Security:**
- Use internal networks only
- Configure firewall rules
- Enable Docker's user namespacing
- Use non-root containers (already configured)

3. **Enable Additional Security:**
```yaml
# Add to services in docker-compose.yml
security_opt:
  - no-new-privileges:true
read_only: true  # Where possible
tmpfs:
  - /tmp:noexec,nosuid,size=100m
```

## 🧪 Testing the Setup

### **Validate Secrets Loading:**
```bash
# Check if secrets are properly mounted
docker compose exec dashboardm8 ls -la /run/secrets/

# Test secret reading
docker compose exec dashboardm8 cat /run/secrets/auth_secret
```

### **Validate Database Connections:**
```bash
# Check PostgreSQL connection
docker compose exec postgresql pg_isready -U cpt_dbuser

# Check MongoDB replica set
docker compose exec mongodb-1 mongosh --eval "rs.status()"
```

### **Application Health Check:**
```bash
# Check application startup
docker compose logs dashboardm8

# Test health endpoint
curl http://localhost:3000/api/health
```

## 🔄 Migration from Existing Setup

If you have an existing setup, follow these steps:

### **1. Backup Current Data:**
```bash
# Backup PostgreSQL
docker exec your-postgres-container pg_dump -U username dbname > backup.sql

# Backup MongoDB
docker exec your-mongo-container mongodump --out /backup/
```

### **2. Extract Secrets:**
```bash
# Extract from your existing .env file
grep "PASSWORD\|SECRET\|KEY" .env > secrets-to-migrate.txt
# Then manually create individual secret files
```

### **3. Test Migration:**
```bash
# Build new setup
./build.sh development

# Verify services start correctly
docker compose ps

# Test application functionality
```

## 📞 Troubleshooting

### **Common Issues:**

#### **Build Fails - Missing Secrets:**
```bash
❌ Error: Missing required secret files
```
**Solution:** Ensure all required secret files exist in `secrets/` directory.

#### **Prisma Generation Fails:**
```bash
❌ Error during Prisma generation
```
**Solution:** Check `.env.build` has correct database URLs with internal service names.

#### **Application Can't Connect to Databases:**
```bash
❌ Database connection failed
```
**Solution:** Verify secret files contain correct connection strings with Docker service names.

#### **Secrets Not Loading:**
```bash
❌ Secret file not found
```
**Solution:** Ensure your application reads from `*_FILE` environment variables pointing to `/run/secrets/*`.

### **Debug Commands:**
```bash
# Check secret mounts
docker compose exec dashboardm8 ls -la /run/secrets/

# View service logs
docker compose logs -f [service-name]

# Check network connectivity
docker compose exec dashboardm8 ping postgresql
docker compose exec dashboardm8 ping mongodb-1
```

## 📚 Additional Resources

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Compose Secrets](https://docs.docker.com/compose/compose-file/compose-file-v3/#secrets)
- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)
- [Prisma Environment Variables](https://www.prisma.io/docs/guides/development-environment/environment-variables)

---

## 🎯 Summary

This secure setup provides:
- **Zero secret exposure** in Docker images or logs
- **Production-ready** secrets management
- **Environment-aware** building and deployment  
- **Git-safe** configuration with proper .gitignore
- **Comprehensive validation** and error handling
- **Easy migration** path from existing setups

The architecture ensures your sensitive data remains protected while maintaining developer productivity and deployment simplicity.