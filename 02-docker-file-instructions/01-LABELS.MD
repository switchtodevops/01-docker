# LABEL Instruction - Complete Guide

> Everything you need to know about using LABEL in Dockerfiles for metadata, documentation, and image organization.

## Table of Contents

1. [Introduction](#introduction)
2. [Syntax](#syntax)
3. [How LABEL Works](#how-label-works)
4. [Industry Standards - OCI Labels](#industry-standards---oci-labels)
5. [Best Practices](#best-practices)
6. [Common Use Cases](#common-use-cases)
7. [Real-World Examples](#real-world-examples)
8. [Label Management](#label-management)
9. [Querying and Filtering](#querying-and-filtering)
10. [Advanced Patterns](#advanced-patterns)
11. [Complete Production Examples](#complete-production-examples)
12. [Troubleshooting](#troubleshooting)

---

## Introduction

### What is LABEL?

The `LABEL` instruction adds metadata to Docker images as key-value pairs. Labels are used for:
- **Documentation** - Author, version, description
- **Automation** - Build information, CI/CD metadata
- **Organization** - Grouping and filtering images
- **Compliance** - License, security, audit information
- **Discovery** - Service mesh, monitoring tools

### Why Use Labels?

```dockerfile
# ❌ Without labels - No metadata
FROM nginx:latest
COPY . /usr/share/nginx/html

# ✅ With labels - Rich metadata
FROM nginx:1.25-alpine
LABEL version="1.2.3" \
      maintainer="devops@company.com" \
      description="Production web server" \
      build-date="2024-02-14"
COPY . /usr/share/nginx/html
```

**Benefits:**
- 📊 Track versions and builds
- 🔍 Filter and search images
- 📝 Document image purpose
- 🤖 Enable automation
- ✅ Meet compliance requirements

---

## Syntax

### Basic Syntax

```dockerfile
LABEL <key>=<value>
LABEL <key>=<value> <key>=<value> ...
```

### Multiple Forms

```dockerfile
# 1. Single label per line
LABEL version="1.0"
LABEL maintainer="devops@example.com"

# 2. Multiple labels in one line
LABEL version="1.0" maintainer="devops@example.com"

# 3. Multi-line format (preferred for readability)
LABEL version="1.0" \
      maintainer="devops@example.com" \
      description="My application" \
      build-date="2024-02-14"
```

### Key Naming Conventions

**Valid Keys:**
- Can contain lowercase and uppercase letters
- Can contain digits
- Can contain periods (.), hyphens (-), underscores (_)
- Can use reverse DNS notation (recommended)

```dockerfile
# ✅ Good key names
LABEL version="1.0"
LABEL com.company.version="1.0"
LABEL org.opencontainers.image.version="1.0"
LABEL build_date="2024-02-14"
LABEL my-custom-label="value"

# ❌ Bad key names (avoid spaces)
LABEL my label="value"
```

### Value Formats

```dockerfile
# Simple string
LABEL version="1.0"

# String with spaces (use quotes)
LABEL description="This is my application"

# JSON format
LABEL com.example.metadata='{"key1":"value1","key2":"value2"}'

# Multi-line value (escape newlines)
LABEL description="Line 1\n\
Line 2\n\
Line 3"

# URL
LABEL org.opencontainers.image.source="https://github.com/company/repo"

# Email
LABEL maintainer="devops@company.com"
```

---

## How LABEL Works

### Label Inheritance

Labels are **inherited** from base images:

```dockerfile
# Base image (mybase)
FROM ubuntu:22.04
LABEL base.version="1.0"
LABEL base.maintainer="base@company.com"

# Child image
FROM mybase:latest
LABEL app.version="2.0"

# Result: Child image has 3 labels:
# - base.version=1.0 (inherited)
# - base.maintainer=base@company.com (inherited)
# - app.version=2.0 (added)
```

### Overriding Labels

Labels can be **overridden** by child images:

```dockerfile
# Base image
FROM ubuntu:22.04
LABEL maintainer="base@company.com"

# Child image - override maintainer
FROM mybase:latest
LABEL maintainer="app@company.com"  # Overrides base label

# Result: maintainer=app@company.com
```

### Label Scope

- ✅ Labels persist in the final image
- ✅ Labels are visible to all containers from the image
- ✅ Labels can be inspected with `docker inspect`
- ❌ Labels don't affect build performance
- ❌ Labels aren't visible during build (use ARG for that)

---

## Industry Standards - OCI Labels

### OCI Image Spec Annotations

The [Open Container Initiative (OCI)](https://github.com/opencontainers/image-spec/blob/main/annotations.md) defines standard labels:

#### Core Labels

```dockerfile
LABEL org.opencontainers.image.created="2024-02-14T10:00:00Z" \
      org.opencontainers.image.authors="DevOps Team <devops@company.com>" \
      org.opencontainers.image.url="https://company.com" \
      org.opencontainers.image.documentation="https://docs.company.com" \
      org.opencontainers.image.source="https://github.com/company/repo" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.revision="abc123def456" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="v1.2.3" \
      org.opencontainers.image.title="My Application" \
      org.opencontainers.image.description="Production-ready application"
```

#### Complete OCI Labels Reference

| Label | Description | Example |
|-------|-------------|---------|
| `org.opencontainers.image.created` | Image creation timestamp (RFC 3339) | `2024-02-14T10:00:00Z` |
| `org.opencontainers.image.authors` | Contact details of image maintainers | `John Doe <john@company.com>` |
| `org.opencontainers.image.url` | URL to find more information | `https://company.com` |
| `org.opencontainers.image.documentation` | URL to documentation | `https://docs.company.com` |
| `org.opencontainers.image.source` | URL to source code | `https://github.com/company/repo` |
| `org.opencontainers.image.version` | Version of the packaged software | `1.2.3` |
| `org.opencontainers.image.revision` | Source control revision (git SHA) | `abc123def456...` |
| `org.opencontainers.image.vendor` | Name of distributing entity | `Company Inc` |
| `org.opencontainers.image.licenses` | License(s) (SPDX format) | `Apache-2.0` or `MIT` |
| `org.opencontainers.image.ref.name` | Name of the reference for a target | `v1.2.3` or `latest` |
| `org.opencontainers.image.title` | Human-readable title | `My Application` |
| `org.opencontainers.image.description` | Human-readable description | `Production web server` |
| `org.opencontainers.image.base.digest` | Digest of base image | `sha256:abc123...` |
| `org.opencontainers.image.base.name` | Image reference of base image | `ubuntu:22.04` |

### Using Build Arguments with OCI Labels

```dockerfile
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG GIT_BRANCH

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.ref.name="${GIT_BRANCH}"
```

**Build command:**
```bash
docker build \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg VERSION=1.2.3 \
  --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
  --build-arg GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
  -t myapp:1.2.3 .
```

---

## Best Practices

### 1. Use Standard Namespaces

```dockerfile
# ✅ Good - Use OCI standard
LABEL org.opencontainers.image.version="1.0"

# ✅ Good - Use company namespace
LABEL com.company.team="backend"
LABEL com.company.cost-center="engineering"

# ⚠️ Avoid - Generic keys without namespace
LABEL version="1.0"
LABEL team="backend"
```

### 2. Group Related Labels

```dockerfile
# ✅ Good - Group labels logically
LABEL org.opencontainers.image.created="2024-02-14T10:00:00Z" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.revision="abc123" \
      org.opencontainers.image.authors="devops@company.com"

# ❌ Bad - Scattered labels
LABEL org.opencontainers.image.created="2024-02-14T10:00:00Z"
RUN apt-get update
LABEL org.opencontainers.image.version="1.2.3"
COPY . /app
LABEL org.opencontainers.image.authors="devops@company.com"
```

### 3. Use Multi-line Format

```dockerfile
# ✅ Good - Readable multi-line format
LABEL maintainer="devops@company.com" \
      version="1.2.3" \
      description="Production web application" \
      build-date="2024-02-14"

# ❌ Bad - Hard to read single line
LABEL maintainer="devops@company.com" version="1.2.3" description="Production web application" build-date="2024-02-14"
```

### 4. Include Essential Metadata

**Minimum recommended labels:**
```dockerfile
LABEL org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.authors="devops@company.com" \
      org.opencontainers.image.description="Brief description" \
      org.opencontainers.image.source="https://github.com/company/repo"
```

### 5. Use Quotes for Values with Spaces

```dockerfile
# ✅ Good
LABEL description="This is my application"

# ❌ Bad (will fail)
LABEL description=This is my application
```

### 6. Keep Labels Concise

```dockerfile
# ✅ Good - Concise
LABEL description="Production REST API"

# ⚠️ Avoid - Too verbose
LABEL description="This is a production-ready RESTful API service that handles user authentication, data processing, and integration with third-party services..."
```

### 7. Don't Store Secrets in Labels

```dockerfile
# ❌ NEVER DO THIS
LABEL database.password="secret123"
LABEL api.key="abc123xyz"

# ✅ Use environment variables or secrets management instead
```

---

## Common Use Cases

### 1. Version Tracking

```dockerfile
FROM node:18-alpine

LABEL version="1.2.3" \
      release="stable" \
      release-date="2024-02-14"
```

### 2. Maintainer Information

```dockerfile
FROM python:3.11-slim

LABEL maintainer="DevOps Team <devops@company.com>" \
      team="backend-team" \
      contact="slack:#backend-support"
```

### 3. Build Metadata

```dockerfile
ARG BUILD_DATE
ARG GIT_COMMIT
ARG CI_BUILD_NUMBER

FROM ubuntu:22.04

LABEL build.date="${BUILD_DATE}" \
      build.commit="${GIT_COMMIT}" \
      build.number="${CI_BUILD_NUMBER}" \
      build.tool="GitHub Actions"
```

### 4. License and Compliance

```dockerfile
FROM nginx:alpine

LABEL license="Apache-2.0" \
      vendor="Company Inc" \
      compliance.level="SOC2" \
      security.scan-status="passed"
```

### 5. Environment Tagging

```dockerfile
FROM myapp:base

LABEL environment="production" \
      deployment.region="us-east-1" \
      deployment.zone="az1"
```

### 6. Service Discovery

```dockerfile
FROM myapp:latest

LABEL service.name="api-gateway" \
      service.port="8080" \
      service.protocol="http" \
      service.health-endpoint="/health"
```

### 7. Cost Allocation

```dockerfile
FROM myapp:base

LABEL cost.center="engineering" \
      cost.project="project-alpha" \
      cost.team="backend" \
      cost.owner="john.doe@company.com"
```

### 8. Monitoring and Observability

```dockerfile
FROM myapp:latest

LABEL monitoring.enabled="true" \
      monitoring.metrics-port="9090" \
      logging.level="info" \
      tracing.enabled="true"
```

---

## Real-World Examples

### Example 1: Node.js Production Application

```dockerfile
# syntax=docker/dockerfile:1

ARG NODE_VERSION=18
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG GIT_COMMIT

FROM node:${NODE_VERSION}-alpine

# OCI Standard Labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="DevOps Team <devops@company.com>" \
      org.opencontainers.image.url="https://company.com/products/api" \
      org.opencontainers.image.documentation="https://docs.company.com/api" \
      org.opencontainers.image.source="https://github.com/company/api" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="API Service" \
      org.opencontainers.image.description="Production REST API service"

# Company-specific Labels
LABEL com.company.team="backend" \
      com.company.cost-center="engineering" \
      com.company.project="api-v2" \
      com.company.environment="production" \
      com.company.maintainer="backend-team@company.com"

# Technical Labels
LABEL tech.stack="node.js" \
      tech.framework="express" \
      tech.database="postgresql" \
      tech.cache="redis"

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

USER node

EXPOSE 3000

CMD ["node", "server.js"]
```

### Example 2: Python Django Application

```dockerfile
FROM python:3.11-slim

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG GIT_BRANCH

# OCI Labels with build args
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.ref.name="${GIT_BRANCH}" \
      org.opencontainers.image.title="Django Web App" \
      org.opencontainers.image.description="Production Django application" \
      org.opencontainers.image.authors="Web Team <web@company.com>" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="Apache-2.0"

# Application Labels
LABEL app.name="mywebapp" \
      app.component="web" \
      app.version="${VERSION}" \
      app.tier="frontend"

# Build Labels
LABEL build.ci="true" \
      build.pipeline="github-actions" \
      build.python-version="3.11"

# Deployment Labels
LABEL deployment.strategy="rolling" \
      deployment.replicas="3" \
      deployment.region="us-west-2"

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

RUN useradd -r -u 1001 django && \
    chown -R django:django /app

USER django

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
```

### Example 3: Go Microservice

```dockerfile
# syntax=docker/dockerfile:1

# Build stage
FROM golang:1.21-alpine AS builder

ARG VERSION=dev
ARG BUILD_TIME
ARG GIT_COMMIT

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build \
    -ldflags="-X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}" \
    -o app

# Runtime stage
FROM scratch

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

# OCI Labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Payment Service" \
      org.opencontainers.image.description="Microservice for payment processing" \
      org.opencontainers.image.authors="Payments Team <payments@company.com>" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="Proprietary"

# Microservice Labels
LABEL service.name="payment-service" \
      service.type="microservice" \
      service.protocol="grpc" \
      service.port="50051"

# Architecture Labels
LABEL architecture.pattern="microservices" \
      architecture.layer="business-logic" \
      architecture.bounded-context="payments"

COPY --from=builder /build/app /app
USER 65534:65534
EXPOSE 50051
ENTRYPOINT ["/app"]
```

### Example 4: Multi-Stage Build with Different Labels Per Stage

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Base Stage - Common labels
###########################################
FROM node:18-alpine AS base

LABEL stage="base" \
      base.node-version="18" \
      base.os="alpine"

###########################################
# Dependencies Stage
###########################################
FROM base AS dependencies

LABEL stage="dependencies" \
      dependencies.type="production"

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

###########################################
# Builder Stage
###########################################
FROM base AS builder

LABEL stage="builder" \
      builder.tool="webpack"

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

###########################################
# Production Stage - Final labels
###########################################
FROM base AS production

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

# OCI Labels (only in final stage)
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Web Application" \
      org.opencontainers.image.description="Production web application"

# Stage label
LABEL stage="production"

# Application labels
LABEL app.name="webapp" \
      app.version="${VERSION}" \
      app.environment="production"

WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

---

## Label Management

### Viewing Labels

```bash
# View all labels for an image
docker inspect myapp:latest | jq '.[0].Config.Labels'

# View specific label
docker inspect myapp:latest | jq '.[0].Config.Labels.version'

# Format output nicely
docker inspect --format='{{json .Config.Labels}}' myapp:latest | jq

# View labels from running container
docker inspect container_name | jq '.[0].Config.Labels'
```

### Filtering by Labels

```bash
# List images with specific label
docker images --filter "label=version=1.0"

# List images with label key (any value)
docker images --filter "label=maintainer"

# Multiple filters
docker images --filter "label=version=1.0" --filter "label=environment=production"

# List containers by label
docker ps --filter "label=app.name=myapp"

# List stopped containers by label
docker ps -a --filter "label=environment=staging"
```

### Removing Labels

Labels cannot be removed from built images, but you can:

1. **Override in child image:**
```dockerfile
# Set label to empty (not recommended)
LABEL old-label=""
```

2. **Build new image without label:**
```dockerfile
# Simply don't include the label in new build
```

3. **Use label inheritance strategically:**
```dockerfile
# Base image has labels
# Child image adds more but doesn't remove base labels
```

---

## Advanced Patterns

### Pattern 1: Dynamic Labels from CI/CD

**GitHub Actions:**
```yaml
# .github/workflows/build.yml
- name: Build and push
  run: |
    docker build \
      --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
      --build-arg VERSION=${{ github.ref_name }} \
      --build-arg GIT_COMMIT=${{ github.sha }} \
      --build-arg CI_BUILD_NUMBER=${{ github.run_number }} \
      --build-arg CI_BUILD_URL=${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }} \
      -t myapp:${{ github.ref_name }} .
```

**Dockerfile:**
```dockerfile
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT
ARG CI_BUILD_NUMBER
ARG CI_BUILD_URL

FROM node:18-alpine

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      ci.build-number="${CI_BUILD_NUMBER}" \
      ci.build-url="${CI_BUILD_URL}"
```

### Pattern 2: Environment-Specific Labels

```dockerfile
ARG ENVIRONMENT=production

FROM node:18-alpine

# Base labels
LABEL org.opencontainers.image.title="My App"

# Add environment-specific labels
LABEL environment="${ENVIRONMENT}" \
      deployment.target="${ENVIRONMENT}"

# Different builds:
# docker build --build-arg ENVIRONMENT=development -t myapp:dev .
# docker build --build-arg ENVIRONMENT=staging -t myapp:staging .
# docker build --build-arg ENVIRONMENT=production -t myapp:prod .
```

### Pattern 3: Label Inheritance Strategy

```dockerfile
# base-image/Dockerfile
FROM ubuntu:22.04

LABEL org.opencontainers.image.vendor="Company Inc" \
      com.company.base-image="ubuntu-base" \
      com.company.base-version="1.0" \
      com.company.security-scan="passed"

# app-image/Dockerfile
FROM company/ubuntu-base:1.0

# Inherits all base labels
# Add application-specific labels
LABEL org.opencontainers.image.title="My Application" \
      org.opencontainers.image.version="2.0" \
      com.company.application="myapp"

# Result: Image has both base and app labels
```

### Pattern 4: JSON Metadata Labels

```dockerfile
FROM node:18-alpine

# Store complex metadata as JSON
LABEL com.company.dependencies='{ \
        "node": "18.19.0", \
        "npm": "10.2.4", \
        "express": "4.18.2", \
        "database": "postgresql-15" \
      }' \
      com.company.ports='{ \
        "http": 3000, \
        "metrics": 9090, \
        "debug": 9229 \
      }' \
      com.company.health='{ \
        "endpoint": "/health", \
        "interval": 30, \
        "timeout": 5 \
      }'
```

**Query JSON labels:**
```bash
docker inspect myapp:latest | \
  jq '.[0].Config.Labels."com.company.dependencies" | fromjson'
```

### Pattern 5: Compliance and Security Labels

```dockerfile
FROM nginx:alpine

ARG SCAN_DATE
ARG SCAN_TOOL=trivy
ARG CVE_COUNT=0

LABEL security.scan-date="${SCAN_DATE}" \
      security.scan-tool="${SCAN_TOOL}" \
      security.cve-count="${CVE_COUNT}" \
      security.scan-status="passed" \
      compliance.sox="true" \
      compliance.pci-dss="true" \
      compliance.hipaa="false" \
      security.level="high" \
      security.approved-by="security-team@company.com"
```

---

## Complete Production Examples

### Example 1: Full Production Stack

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Build Arguments
###########################################
ARG NODE_VERSION=18
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG CI_BUILD_NUMBER
ARG CI_BUILD_URL
ARG ENVIRONMENT=production

###########################################
# Dependencies Stage
###########################################
FROM node:${NODE_VERSION}-alpine AS dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

###########################################
# Builder Stage
###########################################
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

###########################################
# Production Stage
###########################################
FROM node:${NODE_VERSION}-alpine AS production

# ═══════════════════════════════════════
# OCI Standard Labels
# ═══════════════════════════════════════
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="DevOps Team <devops@company.com>" \
      org.opencontainers.image.url="https://company.com" \
      org.opencontainers.image.documentation="https://docs.company.com" \
      org.opencontainers.image.source="https://github.com/company/repo" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.vendor="Company Inc" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.ref.name="${GIT_BRANCH}" \
      org.opencontainers.image.title="Production API" \
      org.opencontainers.image.description="Production-ready REST API service" \
      org.opencontainers.image.base.name="node:${NODE_VERSION}-alpine"

# ═══════════════════════════════════════
# Build Information
# ═══════════════════════════════════════
LABEL build.date="${BUILD_DATE}" \
      build.version="${VERSION}" \
      build.commit="${GIT_COMMIT}" \
      build.branch="${GIT_BRANCH}" \
      build.number="${CI_BUILD_NUMBER}" \
      build.url="${CI_BUILD_URL}" \
      build.node-version="${NODE_VERSION}" \
      build.tool="GitHub Actions"

# ═══════════════════════════════════════
# Company Metadata
# ═══════════════════════════════════════
LABEL com.company.team="backend" \
      com.company.cost-center="engineering" \
      com.company.project="api-v2" \
      com.company.owner="john.doe@company.com" \
      com.company.slack-channel="#backend-support" \
      com.company.on-call="backend-oncall@company.com"

# ═══════════════════════════════════════
# Application Metadata
# ═══════════════════════════════════════
LABEL app.name="api-service" \
      app.version="${VERSION}" \
      app.environment="${ENVIRONMENT}" \
      app.tier="backend" \
      app.component="api" \
      app.language="javascript" \
      app.runtime="node.js"

# ═══════════════════════════════════════
# Service Discovery
# ═══════════════════════════════════════
LABEL service.name="api" \
      service.port="3000" \
      service.protocol="http" \
      service.health-endpoint="/health" \
      service.metrics-endpoint="/metrics" \
      service.metrics-port="9090"

# ═══════════════════════════════════════
# Deployment Configuration
# ═══════════════════════════════════════
LABEL deployment.strategy="rolling" \
      deployment.replicas="3" \
      deployment.region="us-east-1" \
      deployment.zone="az1" \
      deployment.kubernetes="true"

# ═══════════════════════════════════════
# Monitoring & Observability
# ═══════════════════════════════════════
LABEL monitoring.enabled="true" \
      monitoring.tool="prometheus" \
      logging.enabled="true" \
      logging.format="json" \
      logging.level="info" \
      tracing.enabled="true" \
      tracing.tool="jaeger"

# ═══════════════════════════════════════
# Security & Compliance
# ═══════════════════════════════════════
LABEL security.scan-status="passed" \
      security.scan-tool="trivy" \
      security.level="high" \
      compliance.sox="true" \
      compliance.pci-dss="false" \
      compliance.gdpr="true" \
      license.type="MIT" \
      license.approved="true"

# ═══════════════════════════════════════
# Technical Stack
# ═══════════════════════════════════════
LABEL tech.framework="express" \
      tech.database="postgresql" \
      tech.cache="redis" \
      tech.message-queue="rabbitmq"

# Application setup
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --chown=nodejs:nodejs package*.json ./

USER nodejs

ENV NODE_ENV=production \
    PORT=3000

EXPOSE 3000 9090

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

CMD ["node", "dist/server.js"]
```

### Build Script for Production Example

```bash
#!/bin/bash
# build-production.sh

set -e

# Variables
REGISTRY="myregistry.com"
IMAGE_NAME="api-service"
VERSION=${1:-"1.0.0"}
ENVIRONMENT=${2:-"production"}

# Get build metadata
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CI_BUILD_NUMBER=${CI_BUILD_NUMBER:-"local"}
CI_BUILD_URL=${CI_BUILD_URL:-"local-build"}

# Build image
echo "Building ${IMAGE_NAME}:${VERSION}..."

docker build \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg VERSION="${VERSION}" \
  --build-arg GIT_COMMIT="${GIT_COMMIT}" \
  --build-arg GIT_BRANCH="${GIT_BRANCH}" \
  --build-arg CI_BUILD_NUMBER="${CI_BUILD_NUMBER}" \
  --build-arg CI_BUILD_URL="${CI_BUILD_URL}" \
  --build-arg ENVIRONMENT="${ENVIRONMENT}" \
  -t ${REGISTRY}/${IMAGE_NAME}:${VERSION} \
  -t ${REGISTRY}/${IMAGE_NAME}:latest \
  .

echo "Build complete!"
echo "Image: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"

# Display labels
echo ""
echo "Image Labels:"
docker inspect ${REGISTRY}/${IMAGE_NAME}:${VERSION} | jq '.[0].Config.Labels'
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Labels Not Showing

**Problem:**
```bash
docker inspect myapp:latest | jq '.[0].Config.Labels'
# Returns: null
```

**Solution:**
- Check if LABEL is in the Dockerfile
- Verify you're inspecting the correct image
- Ensure build completed successfully

#### Issue 2: Build Args Not Appearing in Labels

**Problem:**
```dockerfile
ARG VERSION=1.0
LABEL version="${VERSION}"  # Shows as empty
```

**Solution:**
```dockerfile
# ARG must be declared in the same stage where used
FROM node:18-alpine
ARG VERSION=1.0  # Declare here
LABEL version="${VERSION}"  # Now works
```

#### Issue 3: Multi-line Label Breaks Build

**Problem:**
```dockerfile
LABEL description="Line 1
Line 2"  # Build fails
```

**Solution:**
```dockerfile
# Use escaped newlines
LABEL description="Line 1\n\
Line 2"

# Or use single line with spaces
LABEL description="Line 1 Line 2"
```

#### Issue 4: Special Characters in Label Values

**Problem:**
```dockerfile
LABEL message="Don't break!"  # Breaks due to apostrophe
```

**Solution:**
```dockerfile
# Use double quotes for strings with apostrophes
LABEL message="Don't break!"

# Or escape special characters
LABEL message='Don'\''t break!'
```

#### Issue 5: Labels Increase Image Size

**Question:** Do labels make images larger?

**Answer:** 
- Labels add minimal metadata (few KB)
- No impact on layer sizes
- Don't affect performance
- Safe to use extensively

### Best Practices for Label Debugging

```bash
# 1. View all labels formatted
docker inspect myapp:latest --format='{{json .Config.Labels}}' | jq

# 2. Check specific label
docker inspect myapp:latest --format='{{index .Config.Labels "version"}}'

# 3. List all images with labels
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Labels}}"

# 4. Filter images by label
docker images --filter "label=environment=production"

# 5. Compare labels between images
diff <(docker inspect image1:latest | jq '.[0].Config.Labels') \
     <(docker inspect image2:latest | jq '.[0].Config.Labels')
```

---

## Summary

### Key Takeaways

1. **Use OCI Standard Labels** - Follow `org.opencontainers.image.*` convention
2. **Include Essential Metadata** - Version, maintainer, source, description
3. **Use Build Arguments** - Make labels dynamic with build-time values
4. **Namespace Your Labels** - Use reverse DNS notation for custom labels
5. **Group Related Labels** - Organize labels logically
6. **Don't Store Secrets** - Labels are visible to everyone
7. **Use for Automation** - Filter, search, and organize images
8. **Document Everything** - Labels serve as living documentation

### Minimum Recommended Labels

```dockerfile
LABEL org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.authors="devops@company.com" \
      org.opencontainers.image.description="Your application description" \
      org.opencontainers.image.source="https://github.com/your/repo"
```

### Complete Production Template

```dockerfile
ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

FROM your-base-image:tag

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Your App" \
      org.opencontainers.image.description="Your description" \
      org.opencontainers.image.authors="your-team@company.com" \
      org.opencontainers.image.source="https://github.com/your/repo" \
      org.opencontainers.image.vendor="Your Company" \
      org.opencontainers.image.licenses="MIT"

# Add your company-specific labels
LABEL com.company.team="your-team" \
      com.company.project="your-project"

# Rest of your Dockerfile...
```

---

## Additional Resources

### Official Documentation
- [Dockerfile LABEL Reference](https://docs.docker.com/engine/reference/builder/#label)
- [OCI Image Spec Annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md)
- [Docker Object Labels](https://docs.docker.com/config/labels-custom-metadata/)

### Tools
- [jq](https://stedolan.github.io/jq/) - JSON processor for inspecting labels
- [docker-ls](https://github.com/mayflower/docker-ls) - List Docker images with labels
- [Portainer](https://www.portainer.io/) - Docker management UI with label support

### Related Instructions
- [ARG](./13-ARG.MD) - Build-time variables for dynamic labels
- [ENV](./06-ENV.MD) - Runtime environment variables
- [MAINTAINER](./04-LABEL.MD) - Deprecated, use LABEL instead

---

**Last Updated:** February 2026  
**Docker Version:** 24.x and above

---

*This guide covers everything about the LABEL instruction for professional Docker image development.*
