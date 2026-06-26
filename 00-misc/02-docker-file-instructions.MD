# Dockerfile Instructions - Complete Guide

## Table of Contents
- [Overview](#overview)
- [Dockerfile Instruction Summary](#dockerfile-instruction-summary)
- [Detailed Instructions](#detailed-instructions)
  - [FROM](#from)
  - [RUN](#run)
  - [CMD](#cmd)
  - [ENTRYPOINT](#entrypoint)
  - [COPY](#copy)
  - [ADD](#add)
  - [ENV](#env)
  - [ARG](#arg)
  - [WORKDIR](#workdir)
  - [EXPOSE](#expose)
  - [VOLUME](#volume)
  - [USER](#user)
  - [LABEL](#label)
  - [HEALTHCHECK](#healthcheck)
  - [SHELL](#shell)
  - [STOPSIGNAL](#stopsignal)
  - [ONBUILD](#onbuild)
- [Production Best Practices](#production-best-practices)
- [Real-World Examples](#real-world-examples)
- [Common Patterns](#common-patterns)

---

## Overview

A Dockerfile is a text document containing instructions to build a Docker image. Each instruction creates a layer in the final image, and understanding how to use them efficiently is crucial for creating optimized, secure, and maintainable container images.

**Key Principles:**
- Each instruction creates a new layer
- Layers are cached and reused when possible
- Order matters for build optimization
- Minimize layers for smaller images
- Use multi-stage builds for production

---

## Dockerfile Instruction Summary

| Instruction | Purpose | Execution Time |
|-------------|---------|----------------|
| `FROM` | Sets the base image | Build |
| `RUN` | Executes commands during build | Build |
| `CMD` | Default command when container starts | Runtime |
| `ENTRYPOINT` | Configures container as executable | Runtime |
| `COPY` | Copies files/directories into image | Build |
| `ADD` | Copies files with extra features (URL, tar) | Build |
| `ENV` | Sets environment variables | Build & Runtime |
| `ARG` | Defines build-time variables | Build only |
| `WORKDIR` | Sets working directory | Build & Runtime |
| `EXPOSE` | Documents exposed ports | Documentation |
| `VOLUME` | Creates mount point for volumes | Build & Runtime |
| `USER` | Sets user context | Build & Runtime |
| `LABEL` | Adds metadata to image | Build |
| `HEALTHCHECK` | Defines container health check | Runtime |
| `SHELL` | Changes default shell | Build |
| `STOPSIGNAL` | Sets stop signal | Runtime |
| `ONBUILD` | Triggers for child images | Build (deferred) |

---

## Detailed Instructions

### FROM

**Purpose:** Sets the base image for your Docker image.

**Syntax:**
```dockerfile
FROM <image>[:<tag>] [AS <name>]
FROM <image>[@<digest>] [AS <name>]
```

**Examples:**

```dockerfile
# Using specific version (recommended for production)
FROM node:18-alpine

# Using digest for immutability
FROM node@sha256:abc123...

# Multi-stage build with named stage
FROM golang:1.21 AS builder
FROM alpine:3.18 AS runtime

# Scratch image (empty base)
FROM scratch
```

**Production Best Practices:**
- ✅ Always use specific tags, never `latest`
- ✅ Use slim/alpine variants when possible
- ✅ Consider distroless images for production
- ✅ Use digest for absolute reproducibility
- ❌ Avoid `latest` tag in production

**Real-World Scenario:**
```dockerfile
# Production Node.js app with security scanning
FROM node:18.19-alpine3.19 AS base
# Alpine provides smaller image size (40MB vs 900MB for full node image)
```

---

### RUN

**Purpose:** Executes commands during the build process. Each RUN creates a new layer.

**Syntax:**
```dockerfile
RUN <command>                    # Shell form
RUN ["executable", "param1", "param2"]  # Exec form
```

**Examples:**

```dockerfile
# Shell form - runs in /bin/sh -c
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Exec form - no shell processing
RUN ["/bin/bash", "-c", "echo hello"]

# Multi-line with continuation and cleanup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

**Production Best Practices:**
- ✅ Chain commands with `&&` to reduce layers
- ✅ Clean up package manager caches in the same RUN
- ✅ Use `--no-install-recommends` for apt
- ✅ Sort multi-line arguments alphabetically
- ❌ Don't create unnecessary layers

**Real-World Scenario:**
```dockerfile
# Installing Python dependencies efficiently
RUN pip install --no-cache-dir \
    django==4.2.0 \
    psycopg2-binary==2.9.6 \
    celery==5.3.0 \
    redis==4.5.5
```

---

### CMD

**Purpose:** Provides default command and/or parameters for the container. Can be overridden at runtime.

**Syntax:**
```dockerfile
CMD ["executable", "param1", "param2"]     # Exec form (preferred)
CMD ["param1", "param2"]                   # As default params to ENTRYPOINT
CMD command param1 param2                  # Shell form
```

**Examples:**

```dockerfile
# Exec form (preferred - no shell processing)
CMD ["python", "app.py"]

# Shell form (allows variable expansion)
CMD python app.py

# As parameters to ENTRYPOINT
ENTRYPOINT ["python"]
CMD ["app.py"]  # Can be overridden: docker run myimage other.py
```

**Production Best Practices:**
- ✅ Use exec form for better signal handling
- ✅ Use with ENTRYPOINT for flexible configurations
- ⚠️ Only one CMD instruction per Dockerfile (last one wins)

**Real-World Scenario:**
```dockerfile
# Web application with default but overridable command
FROM python:3.11-slim
COPY . /app
WORKDIR /app
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:app"]

# Override: docker run myapp gunicorn --workers 8 app:app
```

---

### ENTRYPOINT

**Purpose:** Configures the container to run as an executable. Unlike CMD, it's not easily overridden.

**Syntax:**
```dockerfile
ENTRYPOINT ["executable", "param1", "param2"]  # Exec form (preferred)
ENTRYPOINT command param1 param2               # Shell form
```

**Examples:**

```dockerfile
# Basic entrypoint
ENTRYPOINT ["python", "app.py"]

# Combined with CMD for default arguments
ENTRYPOINT ["python", "manage.py"]
CMD ["runserver", "0.0.0.0:8000"]

# Using shell script as entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
```

**Production Best Practices:**
- ✅ Use for the main executable
- ✅ Combine with CMD for default overridable args
- ✅ Use entrypoint scripts for initialization logic
- ⚠️ Override with `--entrypoint` flag if needed

**Real-World Scenario:**
```dockerfile
# Database container with initialization script
FROM postgres:15-alpine

COPY init-db.sh /docker-entrypoint-initdb.d/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]

# The entrypoint script handles:
# - Database initialization
# - User creation
# - Permission setup
# - Then executes CMD (postgres)
```

**ENTRYPOINT vs CMD:**
```dockerfile
# CMD - Easy to override
CMD ["python", "app.py"]
# Run: docker run myimage bash  (runs bash instead)

# ENTRYPOINT - Container acts as executable
ENTRYPOINT ["python", "app.py"]
# Run: docker run myimage bash  (runs: python app.py bash)

# Best of both - flexible and predictable
ENTRYPOINT ["python"]
CMD ["app.py"]
# Run: docker run myimage test.py  (runs: python test.py)
```

---

### COPY

**Purpose:** Copies files or directories from build context into the image. Simpler and more transparent than ADD.

**Syntax:**
```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

**Examples:**

```dockerfile
# Copy single file
COPY app.py /app/

# Copy directory
COPY ./src /app/src

# Copy multiple files
COPY package.json package-lock.json /app/

# Copy with ownership
COPY --chown=node:node . /app

# Copy from specific build stage
COPY --from=builder /app/dist /app/dist

# Using wildcards
COPY *.py /app/
```

**Production Best Practices:**
- ✅ Prefer COPY over ADD (more predictable)
- ✅ Copy dependency files first for better caching
- ✅ Use `.dockerignore` to exclude files
- ✅ Set proper ownership with `--chown`
- ✅ Copy in order of change frequency

**Real-World Scenario:**
```dockerfile
# Optimized Node.js build with layer caching
FROM node:18-alpine

WORKDIR /app

# Copy dependency files first (changes less frequently)
COPY package*.json ./
RUN npm ci --only=production

# Copy application code (changes more frequently)
COPY --chown=node:node . .

USER node
CMD ["node", "server.js"]
```

---

### ADD

**Purpose:** Similar to COPY but with additional features (URL downloads, tar extraction). Use COPY unless you need these features.

**Syntax:**
```dockerfile
ADD [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

**Examples:**

```dockerfile
# Auto-extract tar files
ADD app.tar.gz /app/

# Download from URL (not recommended)
ADD https://example.com/file.tar.gz /tmp/

# Regular copy (use COPY instead)
ADD app.py /app/
```

**Production Best Practices:**
- ⚠️ Use COPY instead unless you need ADD's special features
- ✅ Only use ADD for tar extraction
- ❌ Avoid ADD for URLs (use RUN curl/wget instead)

**Real-World Scenario:**
```dockerfile
# When you actually need ADD - extracting archives
FROM alpine:3.18

# ADD automatically extracts tar files
ADD app-v1.2.3.tar.gz /opt/app/

# Equivalent with COPY would require:
# COPY app-v1.2.3.tar.gz /tmp/
# RUN tar -xzf /tmp/app-v1.2.3.tar.gz -C /opt/app/ && rm /tmp/app-v1.2.3.tar.gz
```

---

### ENV

**Purpose:** Sets environment variables available during build and runtime.

**Syntax:**
```dockerfile
ENV <key>=<value> ...
ENV <key> <value>
```

**Examples:**

```dockerfile
# Single variable
ENV NODE_ENV=production

# Multiple variables
ENV APP_HOME=/app \
    APP_USER=appuser \
    APP_PORT=8000

# Using in subsequent instructions
ENV PYTHON_VERSION=3.11
RUN apt-get install python${PYTHON_VERSION}
```

**Production Best Practices:**
- ✅ Use for runtime configuration
- ✅ Group related environment variables
- ✅ Use meaningful names
- ⚠️ Sensitive data should be passed at runtime, not in ENV

**Real-World Scenario:**
```dockerfile
# Production web application
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    APP_HOME=/app \
    USER=appuser

# These ENVs ensure:
# - Immediate log output (PYTHONUNBUFFERED)
# - No .pyc files (PYTHONDONTWRITEBYTECODE)
# - Smaller image size (PIP_NO_CACHE_DIR)
```

---

### ARG

**Purpose:** Defines build-time variables that users can pass at build-time with `docker build --build-arg`.

**Syntax:**
```dockerfile
ARG <name>[=<default value>]
```

**Examples:**

```dockerfile
# With default value
ARG VERSION=1.0.0
ARG PYTHON_VERSION=3.11

# Without default (must be provided at build)
ARG BUILD_DATE
ARG GIT_COMMIT

# Using ARG
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

# ARG before FROM (special case)
ARG BASE_IMAGE=node:18
FROM ${BASE_IMAGE}
```

**Production Best Practices:**
- ✅ Use for build-time configuration
- ✅ Provide sensible defaults
- ✅ Document required ARGs
- ⚠️ ARG values don't persist in final image
- ❌ Don't use ARG for secrets (visible in image history)

**Real-World Scenario:**
```dockerfile
# Multi-environment build
ARG ENVIRONMENT=production
ARG BUILD_VERSION=latest
ARG NODE_ENV=production

FROM node:18-alpine

# ARG needs to be redeclared after FROM
ARG ENVIRONMENT
ARG BUILD_VERSION

LABEL version="${BUILD_VERSION}" \
      environment="${ENVIRONMENT}"

# Copy different config based on environment
COPY config/config.${ENVIRONMENT}.json /app/config.json

# Build command:
# docker build --build-arg ENVIRONMENT=staging --build-arg BUILD_VERSION=1.2.3 -t myapp:1.2.3 .
```

**ARG vs ENV:**
```dockerfile
# ARG - Build time only
ARG BUILD_DATE
RUN echo "Built on: ${BUILD_DATE}"  # Available
CMD echo "Built on: ${BUILD_DATE}"  # NOT available at runtime

# ENV - Build time and Runtime
ENV APP_VERSION=1.0
RUN echo "Version: ${APP_VERSION}"   # Available
CMD echo "Version: ${APP_VERSION}"   # Available at runtime

# Converting ARG to ENV
ARG BUILD_VERSION
ENV APP_VERSION=${BUILD_VERSION}  # Now available at runtime
```

---

### WORKDIR

**Purpose:** Sets the working directory for subsequent instructions and container runtime.

**Syntax:**
```dockerfile
WORKDIR /path/to/directory
```

**Examples:**

```dockerfile
# Absolute path
WORKDIR /app

# Relative path (relative to previous WORKDIR)
WORKDIR /app
WORKDIR src        # Now in /app/src
WORKDIR services   # Now in /app/src/services

# Using environment variables
ENV APP_HOME=/opt/myapp
WORKDIR ${APP_HOME}

# Creates directory if it doesn't exist
WORKDIR /path/that/does/not/exist
```

**Production Best Practices:**
- ✅ Use WORKDIR instead of RUN cd
- ✅ Set early in Dockerfile
- ✅ Use absolute paths for clarity
- ✅ Creates directory automatically

**Real-World Scenario:**
```dockerfile
# Python application structure
FROM python:3.11-slim

# Set working directory early
WORKDIR /app

# Now all subsequent commands run in /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/
COPY tests/ ./tests/

# At runtime, container starts in /app
CMD ["python", "src/main.py"]
```

---

### EXPOSE

**Purpose:** Documents which ports the container listens on. Does NOT actually publish the port.

**Syntax:**
```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

**Examples:**

```dockerfile
# TCP port (default)
EXPOSE 8080

# Multiple ports
EXPOSE 8080 8443

# Specify protocol
EXPOSE 80/tcp
EXPOSE 53/udp

# Common combinations
EXPOSE 3000       # Node.js app
EXPOSE 5432       # PostgreSQL
EXPOSE 6379       # Redis
EXPOSE 27017      # MongoDB
```

**Production Best Practices:**
- ✅ Document all listening ports
- ✅ Use standard ports when possible
- ⚠️ Still need `-p` or `-P` flag to publish ports
- ℹ️ Primarily for documentation

**Real-World Scenario:**
```dockerfile
# Full-stack application
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Document exposed ports
EXPOSE 3000      # Main application
EXPOSE 3001      # Metrics endpoint
EXPOSE 9229      # Node debugger (dev only)

ENV PORT=3000 \
    METRICS_PORT=3001

CMD ["node", "server.js"]

# Run: docker run -p 3000:3000 -p 3001:3001 myapp
```

---

### VOLUME

**Purpose:** Creates a mount point for external volumes or to persist data.

**Syntax:**
```dockerfile
VOLUME ["/path/to/volume"]
VOLUME /path/to/volume
```

**Examples:**

```dockerfile
# Single volume
VOLUME /data

# Multiple volumes
VOLUME ["/var/log", "/var/db"]

# Common use cases
VOLUME /var/lib/mysql          # Database data
VOLUME /var/log/nginx          # Application logs
VOLUME /app/uploads            # User uploads
```

**Production Best Practices:**
- ✅ Use for persistent data
- ✅ Use for logs and uploads
- ✅ Declare volumes for databases
- ⚠️ Data in volumes persists after container deletion
- ℹ️ Prefer named volumes in production

**Real-World Scenario:**
```dockerfile
# PostgreSQL database container
FROM postgres:15-alpine

ENV POSTGRES_PASSWORD=secure_password \
    POSTGRES_DB=myapp \
    PGDATA=/var/lib/postgresql/data

# Persistent database storage
VOLUME /var/lib/postgresql/data

# Also persist logs
VOLUME /var/log/postgresql

EXPOSE 5432

# Run with named volume:
# docker run -v pgdata:/var/lib/postgresql/data postgres:15
```

---

### USER

**Purpose:** Sets the user (and optionally group) for subsequent instructions and runtime.

**Syntax:**
```dockerfile
USER <user>[:<group>]
USER <UID>[:<GID>]
```

**Examples:**

```dockerfile
# Switch to non-root user
USER node

# Specific UID/GID
USER 1000:1000

# Create user first, then switch
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Using with WORKDIR and ownership
RUN mkdir /app && chown appuser:appuser /app
WORKDIR /app
USER appuser
```

**Production Best Practices:**
- ✅ **NEVER run as root in production**
- ✅ Create dedicated non-root user
- ✅ Switch to non-root user before CMD/ENTRYPOINT
- ✅ Use numeric UIDs for better portability
- 🔒 Critical security practice

**Real-World Scenario:**
```dockerfile
# Secure Node.js application
FROM node:18-alpine

# Create app directory
RUN mkdir -p /home/node/app && chown -R node:node /home/node/app

WORKDIR /home/node/app

# Install dependencies as node user
USER node

COPY --chown=node:node package*.json ./
RUN npm ci --only=production

COPY --chown=node:node . .

EXPOSE 3000

# Container runs as non-root user
CMD ["node", "server.js"]

# Security check:
# docker run myapp whoami  # Should output: node
```

---

### LABEL

**Purpose:** Adds metadata to the image as key-value pairs.

**Syntax:**
```dockerfile
LABEL <key>=<value> <key>=<value> ...
```

**Examples:**

```dockerfile
# Single label
LABEL version="1.0"

# Multiple labels
LABEL maintainer="devops@example.com" \
      description="Production web application" \
      version="1.2.3"

# OCI standard labels
LABEL org.opencontainers.image.created="2024-01-15T10:00:00Z" \
      org.opencontainers.image.authors="DevOps Team" \
      org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.vendor="Example Corp" \
      org.opencontainers.image.title="My App" \
      org.opencontainers.image.description="Production application"
```

**Production Best Practices:**
- ✅ Use OCI standard labels
- ✅ Include version, maintainer, description
- ✅ Add build date and commit hash
- ✅ Group labels together

**Real-World Scenario:**
```dockerfile
# Production-grade labeling
FROM node:18-alpine

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="devops@company.com" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="API Service" \
      org.opencontainers.image.description="Production REST API" \
      org.opencontainers.image.vendor="Company Inc" \
      company.app.environment="production" \
      company.app.team="backend-team"

# Build command:
# docker build \
#   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
#   --build-arg VERSION=1.2.3 \
#   --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
#   -t myapp:1.2.3 .

# View labels:
# docker inspect myapp:1.2.3 | jq '.[0].Config.Labels'
```

---

### HEALTHCHECK

**Purpose:** Tells Docker how to test if the container is still working properly.

**Syntax:**
```dockerfile
HEALTHCHECK [OPTIONS] CMD command
HEALTHCHECK NONE  # Disable healthcheck
```

**Options:**
- `--interval=DURATION` (default: 30s)
- `--timeout=DURATION` (default: 30s)
- `--start-period=DURATION` (default: 0s)
- `--retries=N` (default: 3)

**Examples:**

```dockerfile
# Basic HTTP healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Using wget instead of curl
HEALTHCHECK CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# Database healthcheck
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD pg_isready -U postgres || exit 1

# Custom script healthcheck
HEALTHCHECK --interval=30s CMD /app/healthcheck.sh

# Disable inherited healthcheck
HEALTHCHECK NONE
```

**Production Best Practices:**
- ✅ Always include healthchecks in production
- ✅ Check actual application functionality, not just process
- ✅ Set appropriate intervals and timeouts
- ✅ Use start-period for slow-starting apps
- ✅ Return 0 for healthy, 1 for unhealthy

**Real-World Scenario:**
```dockerfile
# Production web application with comprehensive healthcheck
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Healthcheck that verifies:
# 1. Application is responding
# 2. Database connection is working
# 3. Critical services are available
HEALTHCHECK --interval=30s \
            --timeout=10s \
            --start-period=40s \
            --retries=3 \
  CMD python -c "import requests; import sys; \
       r = requests.get('http://localhost:8000/health'); \
       sys.exit(0 if r.status_code == 200 and r.json()['status'] == 'healthy' else 1)"

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]

# Check status:
# docker ps  # Shows health status
# docker inspect --format='{{.State.Health.Status}}' container_name
```

---

### SHELL

**Purpose:** Changes the default shell used for shell-form commands.

**Syntax:**
```dockerfile
SHELL ["executable", "parameters"]
```

**Examples:**

```dockerfile
# Default shell on Linux
SHELL ["/bin/sh", "-c"]

# Use bash instead
SHELL ["/bin/bash", "-c"]

# Use PowerShell on Windows
SHELL ["powershell", "-command"]

# Use with set flags
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
```

**Production Best Practices:**
- ✅ Use bash with error flags for better debugging
- ✅ Set `-euxo pipefail` for strict error handling
- ℹ️ Affects RUN, CMD, and ENTRYPOINT in shell form

**Real-World Scenario:**
```dockerfile
# Production build with strict error handling
FROM ubuntu:22.04

# Use bash with strict mode:
# -e: exit on error
# -u: exit on undefined variable
# -x: print commands (useful for debugging)
# -o pipefail: pipeline fails if any command fails
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y curl && \
    echo "This will fail if any command fails"

# Now all subsequent RUN commands use this shell with strict mode
```

---

### STOPSIGNAL

**Purpose:** Sets the system call signal that will be sent to the container to stop.

**Syntax:**
```dockerfile
STOPSIGNAL signal
```

**Examples:**

```dockerfile
# Use SIGTERM (default)
STOPSIGNAL SIGTERM

# Use SIGQUIT for graceful shutdown
STOPSIGNAL SIGQUIT

# Use SIGINT
STOPSIGNAL SIGINT

# Numeric signal
STOPSIGNAL 9  # SIGKILL (not recommended - no cleanup)
```

**Production Best Practices:**
- ✅ Use SIGTERM for most applications (default)
- ✅ Implement proper signal handling in application
- ✅ Allow graceful shutdown period
- ❌ Avoid SIGKILL (no cleanup opportunity)

**Real-World Scenario:**
```dockerfile
# Node.js application with graceful shutdown
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# SIGTERM allows Node.js to handle graceful shutdown
STOPSIGNAL SIGTERM

EXPOSE 3000

CMD ["node", "server.js"]

# In server.js, handle the signal:
# process.on('SIGTERM', () => {
#   console.log('SIGTERM received, closing server gracefully');
#   server.close(() => {
#     console.log('Server closed');
#     process.exit(0);
#   });
# });
```

---

### ONBUILD

**Purpose:** Adds a trigger instruction to execute later when the image is used as a base for another build.

**Syntax:**
```dockerfile
ONBUILD <INSTRUCTION>
```

**Examples:**

```dockerfile
# In base image
FROM node:18-alpine
ONBUILD COPY package*.json ./
ONBUILD RUN npm install
ONBUILD COPY . .

# In child image (triggers execute automatically)
FROM mycompany/node-base:latest  # ONBUILD instructions execute here
CMD ["node", "server.js"]
```

**Production Best Practices:**
- ⚠️ Use sparingly - can be confusing
- ✅ Good for creating company-standard base images
- ✅ Document ONBUILD triggers clearly
- ℹ️ ONBUILD doesn't trigger on the image being built

**Real-World Scenario:**
```dockerfile
# Company base image: mycompany/python-base
FROM python:3.11-slim

# Setup common for all Python apps
RUN pip install --upgrade pip
ENV PYTHONUNBUFFERED=1

# These run when someone uses this as base
ONBUILD WORKDIR /app
ONBUILD COPY requirements.txt .
ONBUILD RUN pip install -r requirements.txt
ONBUILD COPY . .

# Team members use it:
# FROM mycompany/python-base:latest
# CMD ["python", "app.py"]
# The ONBUILD instructions automatically run
```

---

## Production Best Practices

### 1. Multi-Stage Builds

Reduce final image size by separating build and runtime environments.

```dockerfile
# Stage 1: Build
FROM golang:1.21 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Stage 2: Runtime
FROM alpine:3.18

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy only the binary from builder
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]

# Result: ~10MB instead of ~800MB with full Go image
```

### 2. Layer Caching Optimization

Order instructions from least to most frequently changing.

```dockerfile
FROM node:18-alpine

WORKDIR /app

# 1. Dependencies (changes rarely)
COPY package*.json ./
RUN npm ci --only=production

# 2. Configuration (changes occasionally)
COPY config/ ./config/

# 3. Source code (changes frequently)
COPY src/ ./src/

CMD ["node", "src/server.js"]
```

### 3. Security Best Practices

```dockerfile
FROM node:18-alpine

# 1. Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 2. Install only necessary packages
RUN apk add --no-cache \
    tini \
    dumb-init

# 3. Create app directory with proper ownership
RUN mkdir -p /app && chown nodejs:nodejs /app

WORKDIR /app

# 4. Copy with ownership
COPY --chown=nodejs:nodejs package*.json ./

USER nodejs

RUN npm ci --only=production

COPY --chown=nodejs:nodejs . .

# 5. Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# 6. Healthcheck
HEALTHCHECK --interval=30s CMD node healthcheck.js || exit 1

# 7. Don't expose unnecessary ports
EXPOSE 3000

CMD ["node", "server.js"]
```

### 4. Image Size Optimization

```dockerfile
FROM node:18-alpine AS base

# Use alpine variants
FROM python:3.11-slim-bullseye  # Instead of python:3.11

# Clean up in the same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

# Use .dockerignore
# node_modules/
# .git/
# *.md
# tests/

# Multi-stage to exclude build dependencies
FROM base AS builder
RUN npm ci

FROM base AS production
COPY --from=builder /app/node_modules ./node_modules
```

### 5. Using .dockerignore

```dockerignore
# .dockerignore file
# Version control
.git/
.gitignore
.github/

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc
.venv/

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

# Testing
tests/
test/
*.test.js
*.spec.js
coverage/

# CI/CD
.circleci/
.travis.yml
.gitlab-ci.yml

# Documentation
docs/

# Build artifacts
dist/
build/
*.log
```

---

## Real-World Examples

### Example 1: Production Node.js API

```dockerfile
# Multi-stage Node.js production build
FROM node:18-alpine AS base

# Stage 1: Dependencies
FROM base AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production && \
    npm cache clean --force

# Stage 2: Build (if using TypeScript)
FROM base AS build

WORKDIR /app

COPY package*.json tsconfig.json ./
RUN npm ci

COPY src/ ./src/
RUN npm run build

# Stage 3: Production
FROM base AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    mkdir -p /app && \
    chown -R nodejs:nodejs /app

WORKDIR /app

USER nodejs

# Copy dependencies and built files
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --chown=nodejs:nodejs package*.json ./

# Environment variables
ENV NODE_ENV=production \
    PORT=3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

EXPOSE 3000

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### Example 2: Production Python Django Application

```dockerfile
# Multi-stage Python Django production build
FROM python:3.11-slim-bullseye AS base

# Prevents Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Stage 1: Builder
FROM base AS builder

WORKDIR /app

# Install system dependencies for building
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Production
FROM base AS production

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        postgresql-client \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r django && \
    useradd -r -g django django && \
    mkdir -p /app /app/staticfiles /app/media && \
    chown -R django:django /app

WORKDIR /app

# Copy wheels and install
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

# Copy application
COPY --chown=django:django . .

USER django

# Collect static files
RUN python manage.py collectstatic --noinput

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

EXPOSE 8000

# Run with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", \
     "--worker-class", "gthread", "--worker-tmp-dir", "/dev/shm", \
     "--access-logfile", "-", "--error-logfile", "-", "myproject.wsgi:application"]
```

### Example 3: Production Go Microservice

```dockerfile
# Multi-stage Go microservice build
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}" \
    -a -installsuffix cgo \
    -o /app/server \
    ./cmd/server

# Production stage
FROM scratch

# Copy CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/server /server

# Copy config if needed
COPY config/config.yaml /config/config.yaml

# Expose port
EXPOSE 8080

# Health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/server", "--health-check"]

# Run as non-root (numeric UID for scratch)
USER 65534:65534

ENTRYPOINT ["/server"]

# Final image size: ~10-15MB
```

### Example 4: Production React Frontend

```dockerfile
# Multi-stage React production build
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .

ARG REACT_APP_API_URL
ARG REACT_APP_VERSION

ENV REACT_APP_API_URL=$REACT_APP_API_URL \
    REACT_APP_VERSION=$REACT_APP_VERSION

RUN npm run build

# Production stage with nginx
FROM nginx:1.25-alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=builder /app/build /usr/share/nginx/html

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
```

---

## Common Patterns

### Pattern 1: Init Container Pattern

```dockerfile
FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq

# Copy initialization script
COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Copy application
COPY app /app

WORKDIR /app

# Entrypoint performs initialization
ENTRYPOINT ["/usr/local/bin/init.sh"]

# Then executes the main command
CMD ["./app"]
```

### Pattern 2: Debug vs Production Images

```dockerfile
# Use build args to control debug features
ARG DEBUG=false

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

# Install debug tools only if DEBUG=true
RUN if [ "$DEBUG" = "true" ]; then \
        pip install debugpy ipdb; \
    fi

COPY . .

# Conditional CMD based on debug mode
CMD if [ "$DEBUG" = "true" ]; then \
        python -m debugpy --listen 0.0.0.0:5678 app.py; \
    else \
        python app.py; \
    fi

# Build production: docker build -t app:prod .
# Build debug: docker build --build-arg DEBUG=true -t app:debug .
```

### Pattern 3: Secrets Handling

```dockerfile
# NEVER do this - secrets in image
# ENV DB_PASSWORD=secret123  ❌

# Good approach - use build secrets (Docker BuildKit)
# RUN --mount=type=secret,id=db_password \
#     export DB_PASSWORD=$(cat /run/secrets/db_password) && \
#     ./configure.sh

FROM python:3.11-slim

WORKDIR /app

# Expect secrets at runtime
ENV DB_PASSWORD_FILE=/run/secrets/db_password

COPY . .

# Application reads from file
CMD ["python", "app.py"]

# Run: docker run --secret db_password=./password.txt myapp
```

### Pattern 4: Configuration Management

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY . .

# Support multiple configuration methods
ENV CONFIG_PATH=/app/config/config.json \
    CONFIG_URL="" \
    USE_ENV_VARS=false

# Entrypoint script handles configuration loading
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["node", "server.js"]

# docker-entrypoint.sh can:
# 1. Load config from file (CONFIG_PATH)
# 2. Download config from URL (CONFIG_URL)
# 3. Use environment variables (USE_ENV_VARS)
```

---

## Build Commands Reference

```bash
# Basic build
docker build -t myapp:latest .

# Build with build args
docker build --build-arg VERSION=1.2.3 --build-arg ENV=production -t myapp:1.2.3 .

# Build with specific target (multi-stage)
docker build --target production -t myapp:prod .

# Build with no cache
docker build --no-cache -t myapp:latest .

# Build with build context from URL
docker build -t myapp https://github.com/user/repo.git#branch

# Build with secrets (BuildKit)
DOCKER_BUILDKIT=1 docker build --secret id=mysecret,src=secret.txt -t myapp .

# Build and push
docker build -t myregistry.com/myapp:1.2.3 . && docker push myregistry.com/myapp:1.2.3

# Build with labels
docker build \
  --label "version=1.2.3" \
  --label "commit=$(git rev-parse HEAD)" \
  -t myapp:1.2.3 .
```

---

## Summary

**Key Takeaways:**

1. **Order matters** - Place frequently changing instructions last
2. **Security first** - Always use non-root users in production
3. **Multi-stage builds** - Separate build and runtime environments
4. **Layer caching** - Optimize for build speed and caching
5. **Size optimization** - Use alpine images and clean up in same layer
6. **Health checks** - Always include in production images
7. **Documentation** - Use labels and comments
8. **Secrets** - Never hardcode in Dockerfiles
9. **Testing** - Test images before deploying to production
10. **Standards** - Follow OCI and industry best practices

---

**Additional Resources:**
- [Official Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [OCI Image Spec](https://github.com/opencontainers/image-spec)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

*Last Updated: February 2026*
