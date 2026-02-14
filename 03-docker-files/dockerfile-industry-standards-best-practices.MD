# Dockerfile Industry Standards & Best Practices

> **Complete Guide to Building Production-Grade Docker Images**

## Table of Contents

1. [Introduction](#introduction)
2. [Foundation Principles](#foundation-principles)
3. [Base Image Selection](#base-image-selection)
4. [Dockerfile Structure](#dockerfile-structure)
5. [Multi-Stage Builds](#multi-stage-builds)
6. [Layer Optimization](#layer-optimization)
7. [Security Best Practices](#security-best-practices)
8. [Dependency Management](#dependency-management)
9. [Configuration Management](#configuration-management)
10. [Networking & Ports](#networking--ports)
11. [Logging & Observability](#logging--observability)
12. [Metadata & Labels](#metadata--labels)
13. [Build Process](#build-process)
14. [Testing & Validation](#testing--validation)
15. [CI/CD Integration](#cicd-integration)
16. [Complete Examples](#complete-examples)
17. [Common Mistakes](#common-mistakes)
18. [Checklist](#checklist)

---

## Introduction

### What This Guide Covers

This document outlines **industry-standard practices** for building Docker images that are:
- **Secure** - No vulnerabilities, runs as non-root
- **Small** - Minimal size for faster deployments
- **Fast** - Optimized builds with proper caching
- **Reliable** - Reproducible and deterministic
- **Maintainable** - Easy to update and debug

### Why Standards Matter

- **Security**: Prevents vulnerabilities and breaches
- **Performance**: Faster builds, pulls, and deployments
- **Cost**: Smaller images = less storage and bandwidth
- **Compliance**: Meets enterprise and regulatory requirements
- **Team Efficiency**: Consistent patterns across projects

---

## Foundation Principles

### 1. The Golden Rules

```text
✅ Build once, deploy everywhere
✅ Never run as root in production
✅ Never bake secrets into images
✅ Always use multi-stage builds
✅ Always pin versions and dependencies
✅ Always scan for vulnerabilities
```

### 2. The Container Contract

Before writing a Dockerfile, define:

**Runtime Expectations:**
- What port(s) does it listen on?
- Where does it read configuration? (env vars, files)
- Where does it write logs? (stdout/stderr)
- Is it stateless or does it need volumes?

**Security Requirements:**
- Must run as non-root
- Read-only filesystem support
- No secrets in image layers
- Vulnerability scanning threshold (no Critical/High CVEs)

**Compliance:**
- SBOM (Software Bill of Materials) required?
- Image signing required?
- Regulatory requirements (FIPS, PCI-DSS, SOC2)?

---

## Base Image Selection

### 1. Choose the Right Base

**Options (Smallest to Largest):**

| Base Image | Size | Use Case | Pros | Cons |
|------------|------|----------|------|------|
| `scratch` | 0 MB | Static binaries (Go) | Tiniest possible | No OS, no debugging |
| `distroless` | ~2-20 MB | Production apps | Very secure, no shell | Harder to debug |
| `alpine` | ~5-15 MB | General purpose | Small, popular | musl libc compatibility issues |
| `debian:slim` | ~25-80 MB | Best compatibility | Stable, well-tested | Larger size |
| `ubuntu` | ~30-80 MB | Full features | Familiar, compatible | Larger size |

### 2. Pin Your Base Image

**❌ BAD:**
```dockerfile
FROM node:18
FROM python:3.11
```

**✅ GOOD:**
```dockerfile
# Pin to specific patch version
FROM node:18.19-alpine3.19

# Even better: Pin by digest for immutability
FROM node:18.19-alpine3.19@sha256:c698ffe060d198dcc6647be78ea1683363f12d5d507dc5ec9855f1c55966ffdd
```

**Why?**
- `node:18` can change without warning
- `node:18.19-alpine3.19` is more stable
- `@sha256:...` is completely immutable

### 3. Multi-Architecture Support

```dockerfile
# Supports both AMD64 and ARM64
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"
```

---

## Dockerfile Structure

### 1. Start with Modern Syntax

```dockerfile
# syntax=docker/dockerfile:1.7

# This enables:
# - BuildKit features
# - Better caching
# - Secret mounting
# - SSH mounting
```

### 2. Standard Structure

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Stage 1: Builder (Build artifacts)
###########################################
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency files first (better caching)
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build application
RUN npm run build

###########################################
# Stage 2: Runtime (Production image)
###########################################
FROM node:18-alpine AS runtime

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy only production dependencies
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

# Set ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Environment variables (no secrets!)
ENV NODE_ENV=production \
    PORT=3000

# Document port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

# Use exec form for proper signal handling
CMD ["node", "dist/server.js"]
```

---

## Multi-Stage Builds

### Why Multi-Stage?

**Single Stage (❌ Bad):**
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install  # Includes dev dependencies!
RUN npm run build
CMD ["node", "dist/server.js"]

# Result: 900 MB image with build tools
```

**Multi-Stage (✅ Good):**
```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/server.js"]

# Result: 150 MB image without build tools
```

### Real-World Multi-Stage Examples

**Go Application:**
```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Builder
###########################################
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o app \
    ./cmd/server

###########################################
# Runtime
###########################################
FROM gcr.io/distroless/static-debian12

COPY --from=builder /build/app /app

USER nonroot:nonroot

ENTRYPOINT ["/app"]

# Result: ~5-10 MB image!
```

**Python Application:**
```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Builder
###########################################
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Create wheels
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

###########################################
# Runtime
###########################################
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -u 1001 -g nogroup appuser

WORKDIR /app

# Install from wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/*

COPY . .

RUN chown -R appuser:nogroup /app

USER appuser

CMD ["python", "app.py"]
```

---

## Layer Optimization

### 1. Understand Layer Caching

Docker caches each instruction. If nothing changed, it reuses the cached layer.

**Order Matters:**

```dockerfile
# ❌ BAD: Source code changes invalidate everything
FROM node:18-alpine
WORKDIR /app
COPY . .                    # Changes frequently
RUN npm install             # Gets rebuilt every time
RUN npm run build
CMD ["node", "dist/server.js"]

# ✅ GOOD: Dependencies cached separately
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./       # Changes rarely
RUN npm ci                  # Cached unless package.json changes
COPY . .                    # Changes frequently
RUN npm run build          # Only rebuilds if source changes
CMD ["node", "dist/server.js"]
```

### 2. Combine Related Commands

```dockerfile
# ❌ BAD: Each RUN creates a layer
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ GOOD: Single layer, includes cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### 3. Use BuildKit Cache Mounts

```dockerfile
# Cache npm downloads between builds
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Cache pip downloads
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Cache Go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
```

### 4. Leverage Build Context

Create `.dockerignore`:

```dockerignore
# Version control
.git/
.gitignore
.github/

# Dependencies (install fresh in container)
node_modules/
__pycache__/
*.pyc
.venv/
vendor/

# Development files
*.md
README.md
LICENSE
.env
.env.*
docker-compose*.yml
Dockerfile*

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Testing
tests/
test/
*.test.js
*.spec.js
*.test.py
coverage/
.coverage
htmlcov/

# CI/CD
.circleci/
.travis.yml
.gitlab-ci.yml
.github/

# Build outputs
dist/
build/
target/
*.log
*.out

# Documentation
docs/
*.md
!README.md

# Large files
*.zip
*.tar.gz
*.pdf
*.mp4
*.avi
```

**Benefits:**
- Faster builds (smaller context)
- No accidental secret leaks
- Better caching

---

## Security Best Practices

### 1. Run as Non-Root (CRITICAL)

**❌ NEVER DO THIS:**
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
# Runs as root! Security risk!
```

**✅ ALWAYS DO THIS:**
```dockerfile
FROM node:18-alpine

# Create dedicated user
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001

WORKDIR /app

# Install as root if needed
COPY package*.json ./
RUN npm ci --only=production

# Set ownership
COPY --chown=appuser:appuser . .

# Switch to non-root
USER appuser

CMD ["node", "server.js"]
```

**Why?**
- Root user = full system access if compromised
- Non-root limits damage from vulnerabilities
- Required by most security policies

### 2. Never Bake Secrets Into Images

**❌ DANGEROUS:**
```dockerfile
# Secret will be in image layers forever!
COPY .env /app/.env

# Visible in docker history!
ENV DATABASE_PASSWORD=secret123

# Still visible in image history!
ARG NPM_TOKEN=abc123
RUN npm install --token=$NPM_TOKEN
```

**✅ SAFE:**
```dockerfile
# Use BuildKit secrets (not stored in layers)
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install

# Or pass at runtime
docker run -e DATABASE_PASSWORD=secret123 myapp

# Or use secret files
docker run --secret db_password=./password.txt myapp
```

### 3. Scan for Vulnerabilities

```bash
# Use Trivy (recommended)
trivy image myapp:latest

# Use Docker Scout
docker scout cves myapp:latest

# Use Grype
grype myapp:latest

# Use Snyk
snyk container test myapp:latest
```

**In CI/CD:**
```dockerfile
# Fail build on high/critical CVEs
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest
```

### 4. Use Read-Only Filesystem

```dockerfile
# In Dockerfile
FROM alpine:3.19
RUN mkdir -p /tmp /app/logs && \
    chmod 1777 /tmp

# In docker-compose.yml or K8s
services:
  app:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp
      - /app/logs
```

### 5. Drop Unnecessary Capabilities

```yaml
# Kubernetes SecurityContext
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

### 6. Verify Downloads

```dockerfile
# ❌ BAD: No verification
RUN curl -O https://example.com/app.tar.gz

# ✅ GOOD: Verify checksum
RUN curl -O https://example.com/app.tar.gz && \
    echo "abc123... app.tar.gz" | sha256sum -c - && \
    tar -xzf app.tar.gz
```

### 7. Use Official Images

```dockerfile
# ✅ Official images from Docker Hub
FROM node:18-alpine
FROM python:3.11-slim
FROM postgres:15-alpine

# ✅ Verified publishers
FROM gcr.io/distroless/nodejs18
FROM mcr.microsoft.com/dotnet/runtime:7.0

# ❌ Random user images
FROM randomuser/nodejs
```

---

## Dependency Management

### 1. Pin All Dependencies

**Language Lockfiles:**

| Language | Lockfile | Command |
|----------|----------|---------|
| Node.js | `package-lock.json` | `npm ci` |
| Node.js | `yarn.lock` | `yarn install --frozen-lockfile` |
| Python | `requirements.txt` | `pip install -r requirements.txt` |
| Python | `poetry.lock` | `poetry install --no-dev` |
| Go | `go.sum` | `go mod download` |
| Rust | `Cargo.lock` | `cargo build --release` |
| Java | `pom.xml` / `gradle.lock` | `mvn install` |

**Example:**
```dockerfile
# Node.js with npm
COPY package*.json ./
RUN npm ci --only=production

# Python with pip
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Go
COPY go.mod go.sum ./
RUN go mod download
```

### 2. Use Package Manager Flags

```dockerfile
# Node.js
RUN npm ci --only=production  # Faster, uses lockfile
RUN npm cache clean --force   # Clean cache

# Python
RUN pip install --no-cache-dir -r requirements.txt

# Apt
RUN apt-get install -y --no-install-recommends curl

# Alpine
RUN apk add --no-cache curl
```

### 3. Update Dependencies Regularly

```bash
# Use automation tools
- Renovate Bot (GitHub)
- Dependabot (GitHub)
- WhiteSource Renovate
- Snyk

# Rebuild images even if code didn't change
# to pick up patched base layers
```

---

## Configuration Management

### 1. The 12-Factor Way

**Never bake environment-specific config:**

```dockerfile
# ❌ BAD: Hardcoded config
FROM node:18-alpine
COPY config.production.json /app/config.json
ENV DATABASE_URL=postgres://prod-db:5432/mydb

# ✅ GOOD: Externalized config
FROM node:18-alpine
# Config provided at runtime via env vars or mounted files
```

### 2. Provide Safe Defaults

```dockerfile
# Defaults for local development (not secrets!)
ENV PORT=3000 \
    LOG_LEVEL=info \
    NODE_ENV=production

# Override at runtime:
# docker run -e PORT=8080 -e LOG_LEVEL=debug myapp
```

### 3. Support Multiple Config Methods

```dockerfile
# Priority: env vars > config file > defaults
ENV CONFIG_PATH=/app/config.yaml \
    USE_ENV_CONFIG=true

# App can read from:
# 1. Environment variables (highest priority)
# 2. Mounted config file at $CONFIG_PATH
# 3. Built-in defaults (lowest priority)
```

### 4. Use ConfigMaps and Secrets (Kubernetes)

```yaml
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.yaml: |
    server:
      port: 3000
    logging:
      level: info

---
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db-password: cGFzc3dvcmQxMjM=  # base64 encoded
```

---

## Networking & Ports

### 1. Document Exposed Ports

```dockerfile
# EXPOSE documents the port (doesn't publish it)
EXPOSE 3000

# Multiple ports
EXPOSE 3000 3001 9229

# Specify protocol
EXPOSE 8080/tcp
EXPOSE 53/udp
```

### 2. Bind to 0.0.0.0 (Not localhost)

```javascript
// ❌ BAD: Only accessible inside container
app.listen(3000, 'localhost');

// ✅ GOOD: Accessible from outside
app.listen(3000, '0.0.0.0');
```

```python
# ❌ BAD
app.run(host='127.0.0.1', port=5000)

# ✅ GOOD
app.run(host='0.0.0.0', port=5000)
```

### 3. Avoid Privileged Ports

```dockerfile
# ❌ BAD: Requires root or capabilities
EXPOSE 80
EXPOSE 443

# ✅ GOOD: Use high ports
EXPOSE 8080
EXPOSE 8443

# In production, use ingress/load balancer
# to map 80 -> 8080, 443 -> 8443
```

---

## Logging & Observability

### 1. Log to stdout/stderr

```dockerfile
# ❌ BAD: Log files inside container
RUN mkdir /var/log/app
CMD ["app", "--log-file=/var/log/app/app.log"]

# ✅ GOOD: Log to stdout
CMD ["app", "--log-to-stdout"]
```

**Why?**
- Container orchestrators collect stdout/stderr
- No disk space issues
- Easier centralized logging
- Works with `docker logs`

### 2. Use Structured Logging

```json
{
  "timestamp": "2024-02-14T10:30:00Z",
  "level": "INFO",
  "message": "Request processed",
  "request_id": "abc-123",
  "user_id": "user-456",
  "duration_ms": 45
}
```

### 3. Add Health Checks

```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Custom script
HEALTHCHECK --interval=30s CMD /app/healthcheck.sh

# Database health
HEALTHCHECK CMD pg_isready -U postgres || exit 1
```

**Health Endpoint Example:**
```javascript
// /health endpoint
app.get('/health', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    disk: await checkDiskSpace()
  };
  
  const healthy = Object.values(checks).every(c => c.healthy);
  res.status(healthy ? 200 : 503).json(checks);
});
```

### 4. Expose Metrics

```dockerfile
# Prometheus metrics port
EXPOSE 3000      # Application
EXPOSE 9090      # Metrics endpoint

# Grafana, Datadog, New Relic, etc.
```

### 5. Handle Signals Gracefully

```javascript
// Node.js graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

// Give connections time to close
setTimeout(() => {
  console.log('Forcing exit');
  process.exit(1);
}, 10000);
```

```python
# Python graceful shutdown
import signal
import sys

def signal_handler(sig, frame):
    print('SIGTERM received, shutting down...')
    # Close database connections
    # Stop background tasks
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
```

---

## Metadata & Labels

### 1. OCI Standard Labels

```dockerfile
LABEL org.opencontainers.image.created="2024-02-14T10:00:00Z" \
      org.opencontainers.image.authors="devops@company.com" \
      org.opencontainers.image.url="https://company.com" \
      org.opencontainers.image.documentation="https://docs.company.com" \
      org.opencontainers.image.source="https://github.com/company/repo" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.revision="abc123..." \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="My Application" \
      org.opencontainers.image.description="Production REST API"
```

### 2. Dynamic Labels with Build Args

```dockerfile
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL build.date="${BUILD_DATE}" \
      build.version="${VERSION}" \
      build.commit="${GIT_COMMIT}"
```

**Build Command:**
```bash
docker build \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg VERSION=1.2.3 \
  --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
  -t myapp:1.2.3 .
```

### 3. Custom Labels

```dockerfile
LABEL company.team="backend" \
      company.cost-center="engineering" \
      company.environment="production" \
      company.compliance="pci-dss"
```

### 4. View Labels

```bash
# Inspect labels
docker inspect myapp:latest | jq '.[0].Config.Labels'

# Filter by label
docker images --filter "label=company.team=backend"
```

---

## Build Process

### 1. Use BuildKit

```bash
# Enable BuildKit (recommended)
export DOCKER_BUILDKIT=1

# Or use buildx
docker buildx build -t myapp:latest .
```

**Benefits:**
- Parallel builds
- Better caching
- Secret mounting
- SSH mounting
- Progress output

### 2. Build with Cache

```bash
# Local cache
docker buildx build \
  --cache-from type=local,src=/tmp/docker-cache \
  --cache-to type=local,dest=/tmp/docker-cache \
  -t myapp:latest .

# Registry cache
docker buildx build \
  --cache-from type=registry,ref=myregistry.com/myapp:cache \
  --cache-to type=registry,ref=myregistry.com/myapp:cache \
  -t myapp:latest .
```

### 3. Multi-Platform Builds

```bash
# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapp:latest \
  --push \
  .
```

### 4. Build Targets

```bash
# Build specific stage
docker build --target builder -t myapp:builder .
docker build --target runtime -t myapp:latest .

# Debug build
docker build --target debug -t myapp:debug .
```

---

## Testing & Validation

### 1. Test the Image

```bash
# 1. Start container
docker run -d --name test-app -p 3000:3000 myapp:latest

# 2. Test health endpoint
curl http://localhost:3000/health

# 3. Check logs
docker logs test-app

# 4. Verify non-root
docker exec test-app whoami  # Should not be root

# 5. Test graceful shutdown
docker stop test-app  # Should stop cleanly within timeout

# 6. Clean up
docker rm test-app
```

### 2. Automated Testing

```bash
# Container structure tests
container-structure-test test \
  --image myapp:latest \
  --config test-config.yaml
```

**test-config.yaml:**
```yaml
schemaVersion: '2.0.0'
fileExistenceTests:
  - name: 'App files exist'
    path: '/app/dist'
    shouldExist: true
    
commandTests:
  - name: "Non-root user"
    command: "whoami"
    expectedOutput: ["appuser"]
    
  - name: "Node version"
    command: "node"
    args: ["--version"]
    expectedOutput: ["v18.*"]

metadataTest:
  exposedPorts: ["3000"]
  env:
    - key: NODE_ENV
      value: production
```

### 3. Security Scanning

```bash
# Trivy scan
trivy image --severity HIGH,CRITICAL myapp:latest

# Fail on vulnerabilities
trivy image --severity CRITICAL --exit-code 1 myapp:latest

# Generate report
trivy image -f json -o report.json myapp:latest
```

### 4. Size Check

```bash
# Check image size
docker images myapp:latest

# Analyze layers
docker history myapp:latest

# Use dive for detailed analysis
dive myapp:latest
```

### 5. Lint Dockerfile

```bash
# Hadolint (Dockerfile linter)
hadolint Dockerfile

# With rules
hadolint --ignore DL3008 --ignore DL3009 Dockerfile
```

---

## CI/CD Integration

### 1. GitHub Actions Example

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
            
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:cache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:cache,mode=max
          build-args: |
            BUILD_DATE=${{ steps.meta.outputs.created }}
            VERSION=${{ steps.meta.outputs.version }}
            GIT_COMMIT=${{ github.sha }}
            
      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          
      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

### 2. GitLab CI Example

```yaml
stages:
  - build
  - test
  - scan
  - push

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build
      --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      --build-arg VERSION=$CI_COMMIT_TAG
      --build-arg GIT_COMMIT=$CI_COMMIT_SHA
      --tag $IMAGE_TAG
      --cache-from $CI_REGISTRY_IMAGE:cache
      .
    - docker push $IMAGE_TAG

test:
  stage: test
  image: docker:24
  script:
    - docker run --rm $IMAGE_TAG npm test

scan:
  stage: scan
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE_TAG

push:
  stage: push
  image: docker:24
  only:
    - main
    - tags
  script:
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
```

### 3. Tagging Strategy

```bash
# Immutable tags (recommended)
myapp:1.2.3                    # Semantic version
myapp:1.2.3-alpine             # With base image variant
myapp:abc123                   # Git commit SHA (short)
myapp:abc123def456...          # Git commit SHA (full)
myapp:pr-123                   # Pull request
myapp:main-abc123              # Branch + commit

# Mutable tags (use carefully)
myapp:latest                   # Latest build (avoid in production)
myapp:1.2                      # Minor version
myapp:1                        # Major version
myapp:dev                      # Development build
myapp:staging                  # Staging environment
```

**Best Practice:**
```bash
# Build with multiple tags
docker buildx build \
  -t myapp:1.2.3 \
  -t myapp:1.2 \
  -t myapp:latest \
  -t myapp:$(git rev-parse --short HEAD) \
  --push \
  .

# Deploy by digest (most secure)
kubectl set image deployment/myapp \
  myapp=myapp@sha256:abc123...
```

---

## Complete Examples

### Example 1: Node.js Production App

```dockerfile
# syntax=docker/dockerfile:1.7

###########################################
# Stage 1: Dependencies
###########################################
FROM node:18.19-alpine3.19 AS deps

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install production dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

###########################################
# Stage 2: Builder
###########################################
FROM node:18.19-alpine3.19 AS builder

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Build application
RUN npm run build

###########################################
# Stage 3: Runtime
###########################################
FROM node:18.19-alpine3.19 AS runtime

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy production dependencies
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Switch to non-root user
USER nodejs

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    NODE_OPTIONS="--max-old-space-size=2048"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

# OCI labels
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="My Node.js API" \
      org.opencontainers.image.description="Production REST API"

# Use dumb-init and exec form
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### Example 2: Python Django App

```dockerfile
# syntax=docker/dockerfile:1.7

###########################################
# Stage 1: Builder
###########################################
FROM python:3.11.8-slim-bookworm AS builder

# Prevent Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Create Python wheels
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

###########################################
# Stage 2: Runtime
###########################################
FROM python:3.11.8-slim-bookworm AS runtime

# Runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DJANGO_SETTINGS_MODULE=myproject.settings.production

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        postgresql-client \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r django && \
    useradd -r -g django -u 1001 django && \
    mkdir -p /app /app/staticfiles /app/media && \
    chown -R django:django /app

WORKDIR /app

# Install Python packages from wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/* && \
    rm -rf /wheels

# Copy application code
COPY --chown=django:django . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Switch to non-root user
USER django

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# OCI labels
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Django Application" \
      org.opencontainers.image.description="Production Django API"

# Run with Gunicorn
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--threads", "2", \
     "--worker-class", "gthread", \
     "--worker-tmp-dir", "/dev/shm", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "myproject.wsgi:application"]
```

### Example 3: Go Microservice

```dockerfile
# syntax=docker/dockerfile:1.7

###########################################
# Stage 1: Builder
###########################################
FROM golang:1.21.7-alpine3.19 AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Cache Go modules
COPY go.mod go.sum ./
RUN go mod download && \
    go mod verify

# Copy source code
COPY . .

# Build binary
ARG VERSION=dev
ARG BUILD_TIME
ARG GIT_COMMIT

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s \
    -X main.Version=${VERSION} \
    -X main.BuildTime=${BUILD_TIME} \
    -X main.GitCommit=${GIT_COMMIT}" \
    -a -installsuffix cgo \
    -o /app/server \
    ./cmd/server

###########################################
# Stage 2: Runtime (Distroless)
###########################################
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/server /server

# Copy config (if needed)
COPY config/config.yaml /config/config.yaml

# Run as non-root (distroless nonroot user)
USER nonroot:nonroot

# Expose port
EXPOSE 8080

# Health check (note: no curl in distroless)
# Use liveness/readiness probes in Kubernetes instead
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/server", "--health-check"]

# OCI labels
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Go Microservice" \
      org.opencontainers.image.description="Production Go API"

# Run binary
ENTRYPOINT ["/server"]
CMD ["--config=/config/config.yaml"]

# Final image size: ~5-10 MB!
```

### Example 4: React Frontend with Nginx

```dockerfile
# syntax=docker/dockerfile:1.7

###########################################
# Stage 1: Builder
###########################################
FROM node:18.19-alpine3.19 AS builder

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build arguments for environment-specific builds
ARG REACT_APP_API_URL
ARG REACT_APP_VERSION

# Build application
RUN npm run build

###########################################
# Stage 2: Runtime with Nginx
###########################################
FROM nginx:1.25.3-alpine AS runtime

# Install curl for health checks
RUN apk add --no-cache curl

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=builder /app/build /usr/share/nginx/html

# Create non-root user (nginx alpine doesn't have one by default)
RUN addgroup -g 101 -S nginx && \
    adduser -S nginx -u 101 -G nginx || true

# Set ownership
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port (8080 for non-root)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# OCI labels
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="React Frontend" \
      org.opencontainers.image.description="Production React Application"

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf:**
```nginx
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
}
```

**default.conf:**
```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## Common Mistakes

### ❌ Mistake 1: Running as Root

```dockerfile
# DON'T DO THIS
FROM node:18
WORKDIR /app
COPY . .
CMD ["node", "server.js"]  # Runs as root!
```

**Impact**: Security vulnerability, fails security scans

### ❌ Mistake 2: Secrets in Image

```dockerfile
# DON'T DO THIS
COPY .env /app/.env
ENV API_KEY=secret123
ARG PRIVATE_TOKEN=abc
```

**Impact**: Secrets leaked in image layers forever

### ❌ Mistake 3: Using latest Tag

```dockerfile
# DON'T DO THIS
FROM node:latest
FROM python:latest
```

**Impact**: Unpredictable builds, breaks reproducibility

### ❌ Mistake 4: No .dockerignore

```text
# Without .dockerignore, these get copied:
- node_modules/ (100 MB+)
- .git/ (huge)
- .env (secrets!)
- test files (unnecessary)
```

**Impact**: Slow builds, large images, secret leaks

### ❌ Mistake 5: Poor Layer Caching

```dockerfile
# DON'T DO THIS
FROM node:18
COPY . .              # All files change = cache miss
RUN npm install       # Always reinstalls
```

**Impact**: Every build takes 10+ minutes

### ❌ Mistake 6: Not Using Multi-Stage

```dockerfile
# DON'T DO THIS
FROM node:18
RUN npm install       # Dev dependencies included
RUN npm run build
CMD ["node", "dist/server.js"]
```

**Impact**: 900 MB image instead of 150 MB

### ❌ Mistake 7: Forgetting to Clean Up

```dockerfile
# DON'T DO THIS
RUN apt-get update
RUN apt-get install -y curl
# Leaves cache in layer!
```

**Impact**: Bloated images

### ❌ Mistake 8: Shell Form CMD

```dockerfile
# DON'T DO THIS
CMD node server.js    # Shell form
```

**Impact**: Breaks signal handling (SIGTERM)

### ❌ Mistake 9: Binding to localhost

```javascript
// DON'T DO THIS
app.listen(3000, 'localhost');
```

**Impact**: Not accessible from outside container

### ❌ Mistake 10: No Health Checks

```dockerfile
# Missing health check
```

**Impact**: Orchestrators can't detect failures

---

## Checklist

### Before Committing Dockerfile

- [ ] Uses specific base image version (not `latest`)
- [ ] Includes `.dockerignore` file
- [ ] Uses multi-stage build
- [ ] Runs as non-root user
- [ ] No secrets in image
- [ ] Dependencies pinned with lockfiles
- [ ] Layers optimized (dependencies before source)
- [ ] Cleanup commands in same RUN
- [ ] Uses exec form for CMD/ENTRYPOINT
- [ ] Includes HEALTHCHECK
- [ ] Exposes correct ports
- [ ] Includes OCI labels
- [ ] Documented in README

### Before Pushing to Registry

- [ ] Image builds successfully
- [ ] Container starts without errors
- [ ] Health check passes
- [ ] Runs as non-root (verified)
- [ ] Responds to SIGTERM gracefully
- [ ] Vulnerability scan passed
- [ ] Size is reasonable
- [ ] Dockerfile linted (hadolint)
- [ ] Tested in environment similar to production
- [ ] Tagged with immutable tag (commit SHA)
- [ ] SBOM generated (if required)
- [ ] Image signed (if required)

### Production Deployment

- [ ] Deployed by digest (not tag)
- [ ] Resource limits set
- [ ] Liveness/readiness probes configured
- [ ] Security context configured
- [ ] Secrets mounted (not in env vars)
- [ ] Logging configured
- [ ] Metrics endpoint exposed
- [ ] Monitoring alerts set up
- [ ] Rollback plan tested
- [ ] Documentation updated

---

## Summary

### The 10 Commandments of Dockerfile Best Practices

1. **Thou shalt use specific base image versions** - Never use `latest`
2. **Thou shalt run as non-root** - Security is non-negotiable
3. **Thou shalt never bake secrets** - Use secret managers
4. **Thou shalt use multi-stage builds** - Keep images small
5. **Thou shalt pin all dependencies** - Use lockfiles
6. **Thou shalt optimize layers** - Dependencies first, source last
7. **Thou shalt include health checks** - Enable self-healing
8. **Thou shalt scan for vulnerabilities** - Fail builds on critical CVEs
9. **Thou shalt use exec form** - Enable proper signal handling
10. **Thou shalt document everything** - Labels, README, comments

### Key Takeaways

1. **Security First**: Non-root user, no secrets, scan regularly
2. **Optimize Builds**: Multi-stage, layer caching, .dockerignore
3. **Reproducibility**: Pin versions, use lockfiles, immutable tags
4. **Observability**: Health checks, logging to stdout, metrics
5. **Standards**: OCI labels, semantic versioning, proper metadata

### Additional Resources

- [Official Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OCI Image Specification](https://github.com/opencontainers/image-spec)
- [BuildKit Documentation](https://docs.docker.com/build/buildkit/)
- [Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile linter
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner
- [Dive](https://github.com/wagoodman/dive) - Image layer analyzer

---

**Last Updated**: February 2026  
**Version**: 1.0  
**Author**: DevOps Team

---

*This document represents industry standards as of 2026. Always check for the latest security advisories and best practices.*
