# ADD vs COPY - Complete Docker Instructions Guide

> Comprehensive guide to COPY and ADD instructions with production use cases, best practices, and industry standards

## Table of Contents

1. [Introduction](#introduction)
2. [COPY Instruction](#copy-instruction)
3. [ADD Instruction](#add-instruction)
4. [Key Differences](#key-differences)
5. [When to Use Which](#when-to-use-which)
6. [Production Use Cases](#production-use-cases)
7. [Industry Standards & Best Practices](#industry-standards--best-practices)
8. [Security Considerations](#security-considerations)
9. [Performance Comparison](#performance-comparison)
10. [Real-World Examples](#real-world-examples)
11. [Common Mistakes](#common-mistakes)
12. [Troubleshooting](#troubleshooting)
13. [Decision Matrix](#decision-matrix)

---

## Introduction

### Overview

Both `COPY` and `ADD` are Dockerfile instructions that copy files from your build context into the Docker image. However, they have important differences that affect security, predictability, and use cases.

### Quick Comparison

| Feature | COPY | ADD |
|---------|------|-----|
| **Copy local files** | ✅ Yes | ✅ Yes |
| **Copy from URLs** | ❌ No | ✅ Yes |
| **Auto-extract tar** | ❌ No | ✅ Yes |
| **Transparency** | ✅ High | ⚠️ Lower |
| **Recommended** | ✅ Yes (Default) | ⚠️ Only when needed |
| **Security** | ✅ Safer | ⚠️ Higher risk |
| **Predictability** | ✅ High | ⚠️ Lower |

### Golden Rule

> **Use COPY unless you specifically need ADD's special features (tar extraction or URL downloads)**

---

## COPY Instruction

### What is COPY?

COPY is a straightforward instruction that copies files and directories from your build context (local filesystem) into the Docker image.

### Syntax

```dockerfile
COPY [--chown=<user>:<group>] [--chmod=<perms>] <src>... <dest>

# Alternative syntax (for paths with spaces)
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]

# Copy from another build stage
COPY --from=<stage> <src> <dest>
```

### Basic Examples

```dockerfile
# Copy single file
COPY app.py /app/

# Copy directory
COPY ./src /app/src

# Copy multiple files
COPY file1.txt file2.txt /app/

# Copy everything from current directory
COPY . /app/

# Copy with wildcard
COPY *.py /app/

# Copy and set ownership
COPY --chown=node:node package.json /app/

# Copy with permissions (BuildKit)
COPY --chmod=755 script.sh /usr/local/bin/

# Copy from build stage
COPY --from=builder /app/dist /app/dist
```

### COPY Features

#### 1. Simple and Predictable

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Exactly what you expect - copies files
COPY package.json ./
COPY package-lock.json ./
COPY src/ ./src/

# No surprises, no magic
```

#### 2. Set Ownership During Copy

```dockerfile
FROM node:18-alpine

# Create user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy with ownership in one step (more efficient)
COPY --chown=nodejs:nodejs package*.json ./
COPY --chown=nodejs:nodejs . .

USER nodejs
```

#### 3. Copy from Multi-Stage Builds

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /build
COPY . .
RUN go build -o app

# Production stage
FROM alpine:3.18
WORKDIR /app

# Copy only the binary from builder stage
COPY --from=builder /build/app .

CMD ["./app"]
```

#### 4. Preserve File Metadata

```dockerfile
# COPY preserves:
# - File permissions (except execute bit on Windows)
# - Modification timestamps
# - File ownership (with --chown flag)

COPY --chown=www-data:www-data --chmod=644 index.html /var/www/html/
```

### COPY Best Practices

```dockerfile
# ✅ Good Practices

# 1. Copy dependency files first (better caching)
COPY package.json package-lock.json ./
RUN npm install

# 2. Copy source code after dependencies
COPY . .

# 3. Use .dockerignore to exclude files
# See .dockerignore section below

# 4. Set ownership during copy
COPY --chown=appuser:appuser . /app

# 5. Be explicit with paths
COPY ./config/app.conf /etc/app/
```

---

## ADD Instruction

### What is ADD?

ADD is similar to COPY but with additional features like URL downloads and automatic tar extraction. These extra features make it more powerful but less predictable.

### Syntax

```dockerfile
ADD [--chown=<user>:<group>] [--chmod=<perms>] <src>... <dest>

# Alternative syntax
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

### ADD Special Features

#### Feature 1: Auto-Extract Tar Archives

```dockerfile
# ADD automatically extracts local tar files
ADD app.tar.gz /app/
ADD archive.tar /opt/

# Supported formats:
# - .tar
# - .tar.gz / .tgz
# - .tar.bz2 / .tbz2
# - .tar.xz / .txz

# Result: Contents are extracted, not the tar file itself
```

#### Feature 2: Download from URLs

```dockerfile
# ADD can download from HTTP/HTTPS URLs
ADD https://example.com/config.json /app/config/
ADD https://releases.example.com/app-v1.2.3.tar.gz /tmp/

# ⚠️ Warning: Downloaded files are NOT extracted
# Only LOCAL tar files are auto-extracted
```

### ADD Examples

#### Example 1: Extract Tar Archive

```dockerfile
FROM ubuntu:22.04

# ADD extracts the tar file automatically
ADD application.tar.gz /opt/app/

# Equivalent COPY would require:
# COPY application.tar.gz /tmp/
# RUN tar -xzf /tmp/application.tar.gz -C /opt/app/ && \
#     rm /tmp/application.tar.gz
```

#### Example 2: Download File from URL

```dockerfile
FROM alpine:3.18

# ADD downloads the file
ADD https://raw.githubusercontent.com/user/repo/main/config.yaml /etc/app/

# ⚠️ Better approach with COPY would be:
# RUN apk add --no-cache curl && \
#     curl -fsSL https://raw.githubusercontent.com/user/repo/main/config.yaml \
#          -o /etc/app/config.yaml && \
#     apk del curl
```

#### Example 3: When You Actually Need ADD

```dockerfile
FROM python:3.11-slim

# Scenario: You have a pre-built application archive
# ADD extracts it automatically
ADD myapp-1.0.0.tar.gz /opt/myapp/

WORKDIR /opt/myapp

RUN pip install -r requirements.txt

CMD ["python", "app.py"]
```

---

## Key Differences

### 1. Local Files

```dockerfile
# COPY: Simple file copy
COPY app.py /app/           # Copies app.py to /app/app.py
COPY src/ /app/src/         # Copies directory recursively

# ADD: Same as COPY for regular files
ADD app.py /app/            # Copies app.py to /app/app.py
ADD src/ /app/src/          # Copies directory recursively
```

### 2. Tar Archives

```dockerfile
# COPY: Tar file is copied as-is
COPY archive.tar.gz /app/   # Result: /app/archive.tar.gz (file)

# ADD: Tar file is automatically extracted
ADD archive.tar.gz /app/    # Result: /app/ contains extracted contents
```

### 3. URLs

```dockerfile
# COPY: Cannot download from URLs
COPY https://example.com/file.txt /app/   # ❌ ERROR: Not supported

# ADD: Downloads from URLs
ADD https://example.com/file.txt /app/    # ✅ Downloads file

# ⚠️ Downloaded files are NOT extracted, even if they're tar files
ADD https://example.com/app.tar.gz /tmp/  # Result: /tmp/app.tar.gz (file)
```

### 4. Transparency and Predictability

```dockerfile
# COPY: Always predictable
COPY file.tar.gz /app/      # Always copies the file

# ADD: Behavior depends on source type
ADD file.tar.gz /app/       # Extracts if local, copies if from URL
ADD file.txt /app/          # Copies the file
ADD http://example.com/file /app/  # Downloads the file
```

### 5. Build Cache

```dockerfile
# COPY: Cached by file checksum
COPY app.py /app/           # Cache invalidated only if app.py changes

# ADD (with URL): No cache
ADD https://example.com/config.json /app/  # Downloaded every build
# This is why ADD URLs is not recommended
```

---

## When to Use Which

### Use COPY (95% of cases)

```dockerfile
# ✅ Copying application source code
COPY src/ /app/src/

# ✅ Copying configuration files
COPY config/app.conf /etc/app/

# ✅ Copying dependency files
COPY package.json package-lock.json ./

# ✅ Copying static assets
COPY public/ /var/www/html/

# ✅ Copying from build stages
COPY --from=builder /app/dist ./dist

# ✅ Setting ownership during copy
COPY --chown=node:node . /app
```

### Use ADD (5% of cases)

```dockerfile
# ✅ Extracting local tar archives
ADD myapp-v1.0.0.tar.gz /opt/app/

# ⚠️ Only use ADD when you specifically need:
# 1. Automatic tar extraction
# 2. You have a good reason not to use RUN + tar
```

### Avoid ADD for URLs

```dockerfile
# ❌ Bad: Using ADD for URLs
ADD https://example.com/config.json /app/

# ✅ Good: Use RUN with curl/wget
RUN curl -fsSL https://example.com/config.json -o /app/config.json

# Why? Because RUN with curl allows:
# - Checksum verification
# - Better error handling
# - Conditional downloads
# - Build caching
```

---

## Production Use Cases

### Use Case 1: Standard Application Deployment

```dockerfile
# ✅ Production-Ready Node.js Application
FROM node:18-alpine AS base

# Use COPY for all standard file operations
WORKDIR /app

# Copy dependency files first (better caching)
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY --chown=node:node . .

USER node

CMD ["node", "server.js"]
```

### Use Case 2: Extracting Pre-Built Archives

```dockerfile
# Use Case: Deploying pre-built application archive
FROM tomcat:9-jre11-slim

# ADD for automatic extraction of war files
# (Though COPY + RUN tar is more transparent)
ADD myapp-1.0.0.war /usr/local/tomcat/webapps/

# Better approach (more transparent):
# COPY myapp-1.0.0.war /usr/local/tomcat/webapps/

EXPOSE 8080
CMD ["catalina.sh", "run"]
```

### Use Case 3: Multi-Stage Build with COPY

```dockerfile
# ✅ Production Multi-Stage Build
FROM golang:1.21 AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o app

# Production stage
FROM alpine:3.18

# Install CA certificates
RUN apk --no-cache add ca-certificates

# Copy only the binary (not the entire build context)
COPY --from=builder /build/app /usr/local/bin/app

# Create non-root user
RUN adduser -D -u 1001 appuser
USER appuser

ENTRYPOINT ["/usr/local/bin/app"]
```

### Use Case 4: Configuration Management

```dockerfile
FROM nginx:alpine

# ✅ Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# ✅ Copy SSL certificates
COPY --chown=nginx:nginx ssl/ /etc/nginx/ssl/
RUN chmod 600 /etc/nginx/ssl/*.key

# ✅ Copy static content
COPY --chown=nginx:nginx html/ /usr/share/nginx/html/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```

### Use Case 5: Python Application with Dependencies

```dockerfile
# ✅ Production Python Application
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy requirements first
COPY requirements.txt .

# Install dependencies
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Copy wheels from builder
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/*

# Copy application
COPY --chown=nobody:nogroup . .

# Use non-root user
USER nobody

CMD ["python", "app.py"]
```

### Use Case 6: Legacy Application with Tar Archives

```dockerfile
# When you receive pre-packaged tar archives from vendors
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jre \
        postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ADD to extract vendor-provided archive
# (This is one of the valid use cases for ADD)
ADD vendor-app-v3.2.1.tar.gz /opt/vendor-app/

WORKDIR /opt/vendor-app

# Create data directory
RUN mkdir -p /opt/vendor-app/data && \
    chown -R nobody:nogroup /opt/vendor-app

USER nobody

EXPOSE 8080

CMD ["./bin/start-server.sh"]
```

### Use Case 7: Microservices with Shared Libraries

```dockerfile
# ✅ Microservice with shared libraries from build stage
FROM node:18-alpine AS common

WORKDIR /common

COPY packages/common/package.json ./
RUN npm install

COPY packages/common/ ./

# Service build stage
FROM node:18-alpine AS service-builder

WORKDIR /app

# Copy shared libraries from common stage
COPY --from=common /common /common

COPY services/api/package.json ./
RUN npm install

COPY services/api/ ./

RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy dependencies
COPY --from=service-builder /app/node_modules ./node_modules

# Copy built service
COPY --from=service-builder /app/dist ./dist

# Copy shared libraries
COPY --from=common /common/dist ./node_modules/@company/common

RUN adduser -D -u 1001 appuser && \
    chown -R appuser:appuser /app

USER appuser

CMD ["node", "dist/server.js"]
```

---

## Industry Standards & Best Practices

### 1. Prefer COPY Over ADD

```dockerfile
# ❌ Bad: Using ADD unnecessarily
FROM node:18-alpine
ADD package.json /app/
ADD src/ /app/src/

# ✅ Good: Use COPY for regular files
FROM node:18-alpine
COPY package.json /app/
COPY src/ /app/src/
```

**Why?**
- More predictable behavior
- Clearer intent
- Better security
- Follows Docker best practices

### 2. Use .dockerignore

```dockerignore
# .dockerignore file
# Exclude files you don't want to copy

# Version control
.git/
.gitignore

# Dependencies
node_modules/
__pycache__/
*.pyc

# Build outputs
dist/
build/
target/

# IDE
.vscode/
.idea/

# Logs
*.log

# Environment files
.env
.env.*

# Documentation
README.md
docs/

# Tests
tests/
*.test.js
coverage/
```

### 3. Copy in Order of Change Frequency

```dockerfile
FROM node:18-alpine

WORKDIR /app

# 1. Copy dependency files first (changes rarely)
COPY package.json package-lock.json ./

# 2. Install dependencies (cached if files unchanged)
RUN npm ci --only=production

# 3. Copy source code (changes frequently)
COPY . .

# This order maximizes Docker layer caching
```

### 4. Set Ownership During Copy

```dockerfile
# ❌ Bad: Two-step process
COPY . /app
RUN chown -R appuser:appuser /app

# ✅ Good: Set ownership during copy (more efficient)
COPY --chown=appuser:appuser . /app
```

### 5. Use Explicit Paths

```dockerfile
# ❌ Bad: Implicit destination
COPY app.py /app

# ✅ Good: Explicit file or directory
COPY app.py /app/app.py          # Explicit file
COPY app.py /app/                # Explicit directory (adds trailing /)
```

### 6. Multi-Stage Builds

```dockerfile
# ✅ Best Practice: Multi-stage builds with COPY --from

# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app

# Copy only production dependencies
COPY --from=builder /app/node_modules ./node_modules

# Copy only built artifacts
COPY --from=builder /app/dist ./dist

USER node
CMD ["node", "dist/server.js"]
```

### 7. Verify Checksums for Downloads

```dockerfile
# ✅ Good: Verify downloads with checksum
RUN curl -fsSL https://example.com/app.tar.gz -o /tmp/app.tar.gz && \
    echo "abc123... /tmp/app.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/app.tar.gz -C /opt/app && \
    rm /tmp/app.tar.gz
```

### 8. Use Specific COPY Commands

```dockerfile
# ❌ Bad: Copying everything
COPY . /app/

# ✅ Good: Specific COPY commands
COPY src/ /app/src/
COPY config/ /app/config/
COPY package.json package-lock.json /app/
```

---

## Security Considerations

### 1. COPY is Safer Than ADD

```dockerfile
# ✅ COPY: Predictable, secure
COPY trusted-source.tar.gz /app/
# Result: File is copied as-is

# ⚠️ ADD: Automatic behavior can be exploited
ADD untrusted-source.tar.gz /app/
# Result: File is extracted (could contain malicious files)
```

### 2. Avoid ADD with URLs

```dockerfile
# ❌ Bad: No verification
ADD https://example.com/package.tar.gz /tmp/

# ✅ Good: Verify with checksum
RUN curl -fsSL https://example.com/package.tar.gz -o /tmp/package.tar.gz && \
    echo "expected-sha256-hash /tmp/package.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/package.tar.gz -C /opt && \
    rm /tmp/package.tar.gz
```

### 3. Use Trusted Sources Only

```dockerfile
# ✅ Good: Copy from trusted build context
COPY --from=official-builder /app/dist /app/dist

# ⚠️ Risky: ADD from external URLs
ADD https://untrusted-site.com/binary /usr/local/bin/
```

### 4. Set Proper Permissions

```dockerfile
# ✅ Good: Restrictive permissions
COPY --chmod=644 config.yaml /etc/app/
COPY --chmod=755 start.sh /usr/local/bin/

# ✅ Good: Non-root ownership
COPY --chown=nobody:nogroup . /app/
```

### 5. Avoid Copying Secrets

```dockerfile
# ❌ Never do this
COPY .env /app/
COPY secrets/ /app/secrets/

# ✅ Good: Use build secrets (BuildKit)
RUN --mount=type=secret,id=api_key \
    export API_KEY=$(cat /run/secrets/api_key) && \
    ./configure.sh

# ✅ Good: Pass at runtime
docker run -e API_KEY=secret myapp
```

---

## Performance Comparison

### Build Time Comparison

```dockerfile
# Test 1: COPY vs ADD for regular files
# Time: ~0.1s (both identical)
COPY app.py /app/
ADD app.py /app/

# Test 2: Large directory copy
# COPY: ~2.5s
COPY large-dir/ /app/

# ADD: ~2.5s (identical to COPY for regular files)
ADD large-dir/ /app/

# Test 3: Tar extraction
# COPY + RUN tar: ~5.2s (two layers)
COPY archive.tar.gz /tmp/
RUN tar -xzf /tmp/archive.tar.gz -C /app/

# ADD: ~4.8s (one layer, automatic extraction)
ADD archive.tar.gz /app/

# Test 4: URL download
# ADD: ~3.0s (no caching, downloads every build)
ADD https://example.com/file.tar.gz /tmp/

# RUN curl: ~3.0s (first build), ~0.1s (cached)
RUN curl -fsSL https://example.com/file.tar.gz -o /tmp/file.tar.gz
```

### Layer Size Comparison

```dockerfile
# COPY: Creates one layer with exact file sizes
COPY src/ /app/src/
# Layer size: Size of src/ directory

# ADD with tar: Creates one layer with extracted content
ADD app.tar.gz /app/
# Layer size: Size of extracted content (not tar file)

# COPY + RUN tar: Creates two layers
COPY app.tar.gz /tmp/
RUN tar -xzf /tmp/app.tar.gz -C /app/ && rm /tmp/app.tar.gz
# Layer 1: Size of tar file
# Layer 2: Size of extracted content
# Total: Larger than ADD (tar file + extracted content)
```

### Caching Behavior

```dockerfile
# COPY: Excellent caching (checksum-based)
COPY package.json ./
# Cache is used if package.json hasn't changed

# ADD with local files: Same as COPY
ADD package.json ./
# Cache is used if package.json hasn't changed

# ADD with URLs: No caching
ADD https://example.com/config.json /app/
# Always downloads, cache never used

# RUN with curl: Cacheable
RUN curl -fsSL https://example.com/config.json -o /app/config.json
# Cache is used unless this layer is invalidated
```

---

## Real-World Examples

### Example 1: Production Node.js API

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Dependencies Stage
###########################################
FROM node:18-alpine AS dependencies

WORKDIR /app

# ✅ COPY dependency files
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

###########################################
# Builder Stage
###########################################
FROM node:18-alpine AS builder

WORKDIR /app

# ✅ COPY dependency files
COPY package.json package-lock.json ./

# Install all dependencies (including dev)
RUN npm ci

# ✅ COPY source code
COPY . .

# Build application
RUN npm run build

###########################################
# Production Stage
###########################################
FROM node:18-alpine

# Install dumb-init
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# ✅ COPY production dependencies from dependencies stage
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# ✅ COPY built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# ✅ COPY package files
COPY --chown=nodejs:nodejs package*.json ./

USER nodejs

ENV NODE_ENV=production \
    PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s CMD node healthcheck.js || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### Example 2: Python Application with Virtual Environment

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ✅ COPY requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

###########################################
# Production Stage
###########################################
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -u 1001 -m appuser

WORKDIR /app

# ✅ COPY virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# ✅ COPY application code
COPY --chown=appuser:appuser . .

USER appuser

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

EXPOSE 8000

HEALTHCHECK --interval=30s CMD python healthcheck.py || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

### Example 3: Go Microservice

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Builder Stage
###########################################
FROM golang:1.21-alpine AS builder

# Install build tools
RUN apk add --no-cache git ca-certificates

WORKDIR /build

# ✅ COPY go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && \
    go mod verify

# ✅ COPY source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server

###########################################
# Production Stage
###########################################
FROM scratch

# ✅ COPY CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# ✅ COPY binary
COPY --from=builder /app/server /server

# ✅ COPY configuration
COPY config/config.yaml /config/config.yaml

USER 65534:65534

EXPOSE 8080

HEALTHCHECK --interval=30s CMD ["/server", "--health"]

ENTRYPOINT ["/server"]

# Final image size: ~10-15 MB
```

### Example 4: Frontend Application with Nginx

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Builder Stage
###########################################
FROM node:18-alpine AS builder

WORKDIR /app

# ✅ COPY package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# ✅ COPY source code
COPY . .

# Build production bundle
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

RUN npm run build

###########################################
# Production Stage
###########################################
FROM nginx:1.25-alpine

# ✅ COPY custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# ✅ COPY built assets from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Create non-root user (nginx already exists in alpine)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### Example 5: Java Spring Boot Application

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Builder Stage
###########################################
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# ✅ COPY Maven files
COPY pom.xml .
COPY src ./src

# Build application
RUN mvn clean package -DskipTests

###########################################
# Production Stage
###########################################
FROM eclipse-temurin:17-jre-alpine

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

# ✅ COPY JAR from builder
COPY --from=builder --chown=spring:spring /build/target/*.jar app.jar

USER spring

ENV JAVA_OPTS="-Xms512m -Xmx1024m" \
    SERVER_PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --start-period=60s \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
```

### Example 6: When to Use ADD - Vendor Archive

```dockerfile
# Real scenario: Vendor provides pre-built tar archive
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jre-headless \
        postgresql-client \
        curl && \
    rm -rf /var/lib/apt/lists/*

# ✅ Valid use of ADD: Extract vendor archive
# Vendor provides: oracle-app-v12.2.1.3.0.tar.gz
ADD oracle-app-v12.2.1.3.0.tar.gz /opt/oracle/

WORKDIR /opt/oracle/app

# Set ownership
RUN useradd -r -u 1001 oracle && \
    chown -R oracle:oracle /opt/oracle

# ✅ COPY configuration files (not in archive)
COPY --chown=oracle:oracle config/ ./config/

USER oracle

EXPOSE 1521 8080

HEALTHCHECK --interval=60s CMD ./bin/healthcheck.sh

CMD ["./bin/start.sh"]
```

---

## Common Mistakes

### Mistake 1: Using ADD for Regular Files

```dockerfile
# ❌ Bad: Using ADD unnecessarily
FROM node:18-alpine
ADD package.json /app/
ADD src/ /app/src/

# ✅ Good: Use COPY for regular files
FROM node:18-alpine
COPY package.json /app/
COPY src/ /app/src/
```

### Mistake 2: Using ADD for URLs Without Verification

```dockerfile
# ❌ Bad: No verification
ADD https://example.com/app.tar.gz /tmp/

# ✅ Good: Verify checksum
RUN curl -fsSL https://example.com/app.tar.gz -o /tmp/app.tar.gz && \
    echo "abc123... /tmp/app.tar.gz" | sha256sum -c -
```

### Mistake 3: Not Using .dockerignore

```dockerfile
# ❌ Bad: Copies everything, including junk
COPY . /app/

# Result: Copies node_modules, .git, tests, etc.
```

**.dockerignore:**
```
node_modules/
.git/
tests/
*.md
```

```dockerfile
# ✅ Good: Only copies what's needed
COPY . /app/
```

### Mistake 4: Wrong Copy Order

```dockerfile
# ❌ Bad: Invalidates cache on every code change
COPY . /app/
RUN npm install

# ✅ Good: Dependency layer is cached
COPY package*.json /app/
RUN npm install
COPY . /app/
```

### Mistake 5: Not Setting Ownership

```dockerfile
# ❌ Bad: Extra layer for ownership
COPY . /app/
RUN chown -R appuser:appuser /app/

# ✅ Good: Set ownership during copy
COPY --chown=appuser:appuser . /app/
```

### Mistake 6: Copying Secrets

```dockerfile
# ❌ Never do this
COPY .env /app/
COPY secrets.json /app/
COPY id_rsa /root/.ssh/

# ✅ Use BuildKit secrets or runtime environment
```

### Mistake 7: Not Using Multi-Stage Builds

```dockerfile
# ❌ Bad: Everything in one stage
FROM node:18
COPY . /app/
RUN npm install && npm run build
CMD ["node", "dist/server.js"]
# Result: Large image with build tools

# ✅ Good: Separate build and runtime
FROM node:18 AS builder
COPY . /app/
RUN npm install && npm run build

FROM node:18-alpine
COPY --from=builder /app/dist /app/dist
CMD ["node", "dist/server.js"]
# Result: Smaller image, only runtime files
```

---

## Troubleshooting

### Issue 1: File Not Found

```dockerfile
# Problem
COPY app.py /app/
# Error: COPY failed: file not found in build context

# Solution: Check file location relative to Dockerfile
COPY ./src/app.py /app/
```

### Issue 2: Permissions Denied

```dockerfile
# Problem
COPY script.sh /usr/local/bin/
RUN script.sh
# Error: Permission denied

# Solution: Set executable permissions
COPY --chmod=755 script.sh /usr/local/bin/
# Or
COPY script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/script.sh
```

### Issue 3: ADD Not Extracting

```dockerfile
# Problem
ADD app.tar.gz /app/
# File is copied, not extracted

# Possible causes:
# 1. File downloaded from URL (only local files are extracted)
ADD https://example.com/app.tar.gz /app/  # Not extracted

# 2. File extension not recognized
ADD app.tgz /app/  # Should work (.tgz is supported)

# Solution: Use explicit extraction
RUN tar -xzf /app/app.tar.gz -C /app/ && rm /app/app.tar.gz
```

### Issue 4: Large Build Context

```dockerfile
# Problem: Slow builds
COPY . /app/
# Sending 2GB build context to Docker daemon

# Solution: Use .dockerignore
# .dockerignore:
node_modules/
.git/
dist/
*.log
```

### Issue 5: Ownership Issues

```dockerfile
# Problem
USER appuser
COPY . /app/
# Files owned by root, app can't write

# Solution: Set ownership during copy
USER appuser
COPY --chown=appuser:appuser . /app/
```

---

## Decision Matrix

### When to Use COPY

✅ **Use COPY when:**
- Copying application source code
- Copying configuration files
- Copying static assets
- Copying from build stages
- You want predictable, transparent behavior
- You want better security
- 95% of all use cases

### When to Use ADD

✅ **Use ADD when:**
- Extracting local tar archives automatically
- You have a specific reason not to use `RUN tar`
- 5% of use cases

### Never Use ADD for

❌ **Don't use ADD for:**
- Regular file copying (use COPY)
- Downloading from URLs (use RUN with curl/wget)
- Files that need checksum verification
- When transparency is important

---

## Quick Reference

### COPY Syntax

```dockerfile
# Basic
COPY source destination
COPY src/ /app/src/

# With ownership
COPY --chown=user:group source destination

# With permissions (BuildKit)
COPY --chmod=755 script.sh /usr/local/bin/

# From build stage
COPY --from=builder /app/dist ./dist

# Multiple sources
COPY file1 file2 file3 /app/
```

### ADD Syntax

```dockerfile
# Basic (same as COPY)
ADD source destination

# Auto-extract tar
ADD archive.tar.gz /app/

# Download URL (not recommended)
ADD https://example.com/file /app/

# With ownership
ADD --chown=user:group archive.tar.gz /app/
```

### Best Practices Summary

1. ✅ **Prefer COPY over ADD**
2. ✅ **Use .dockerignore**
3. ✅ **Copy in order of change frequency**
4. ✅ **Set ownership during copy**
5. ✅ **Use multi-stage builds**
6. ✅ **Be explicit with paths**
7. ✅ **Don't copy secrets**
8. ✅ **Verify downloads with checksums**

---

## Summary

### Key Takeaways

| Aspect | COPY | ADD |
|--------|------|-----|
| **Recommendation** | ✅ Use by default | ⚠️ Use only when needed |
| **Transparency** | ✅ High | ⚠️ Lower |
| **Security** | ✅ Safer | ⚠️ Higher risk |
| **Tar extraction** | ❌ Manual | ✅ Automatic |
| **URL downloads** | ❌ Not supported | ✅ Supported (not recommended) |
| **Predictability** | ✅ High | ⚠️ Depends on source |
| **Caching** | ✅ Excellent | ⚠️ Poor for URLs |
| **Use cases** | 95% of scenarios | 5% of scenarios |

### Industry Standard

> **"Use COPY unless you specifically need ADD's tar extraction feature. Never use ADD for URLs."**
> 
> — Docker Best Practices

### Final Recommendation

```dockerfile
# ✅ Production Standard
FROM node:18-alpine

WORKDIR /app

# Use COPY for all regular file operations
COPY package*.json ./
RUN npm ci --only=production

COPY --chown=node:node . .

USER node

CMD ["node", "server.js"]
```

---

## Additional Resources

- [Official Dockerfile COPY Reference](https://docs.docker.com/engine/reference/builder/#copy)
- [Official Dockerfile ADD Reference](https://docs.docker.com/engine/reference/builder/#add)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [BuildKit Documentation](https://docs.docker.com/build/buildkit/)

---

**Last Updated:** February 2026  
**Docker Version:** 24.x and above  
**Recommendation:** Always prefer COPY over ADD

---

*This guide covers everything about COPY and ADD instructions for professional Docker development.*
