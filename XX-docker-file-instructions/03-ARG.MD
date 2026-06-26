# ARG Instruction - Complete Docker Guide

> Comprehensive guide to ARG instruction with build-time variables, best practices, security considerations, and production use cases

## Table of Contents

1. [Introduction](#introduction)
2. [Syntax](#syntax)
3. [How ARG Works](#how-arg-works)
4. [ARG vs ENV](#arg-vs-env)
5. [Scope and Availability](#scope-and-availability)
6. [Industry Standards & Best Practices](#industry-standards--best-practices)
7. [Common Use Cases](#common-use-cases)
8. [Security Considerations](#security-considerations)
9. [Multi-Stage Builds with ARG](#multi-stage-builds-with-arg)
10. [Advanced Patterns](#advanced-patterns)
11. [Real-World Examples](#real-world-examples)
12. [Predefined ARGs](#predefined-args)
13. [Common Mistakes](#common-mistakes)
14. [Troubleshooting](#troubleshooting)
15. [Decision Matrix](#decision-matrix)

---

## Introduction

### What is ARG?

The `ARG` instruction defines build-time variables that users can pass at build-time to customize the Docker image build process. Unlike `ENV`, ARG variables are **only available during the build** and do not persist in the final image.

### Key Characteristics

- ✅ **Build-time only** - Not available in running containers
- ✅ **Customizable** - Can be overridden with `--build-arg`
- ✅ **Secure** - Not persisted in image (when used correctly)
- ✅ **Flexible** - Enable dynamic image builds
- ⚠️ **Cache impact** - Changes bust build cache
- ⚠️ **Stored in history** - Values visible in `docker history`

### Quick Comparison: ARG vs ENV

| Feature | ARG | ENV |
|---------|-----|-----|
| **Available during** | Build time | Build & runtime |
| **Persists in image** | ❌ No | ✅ Yes |
| **Override method** | `--build-arg` | `--env` or `-e` |
| **Visible in container** | ❌ No | ✅ Yes |
| **Use for secrets** | ⚠️ Risky | ❌ Never |
| **Cache busting** | ✅ Yes | ✅ Yes |

### Golden Rules

> **Use ARG for build-time configuration, ENV for runtime configuration**

> **Never use ARG for secrets - they are stored in image history**

> **Always provide default values for ARGs when possible**

---

## Syntax

### Basic Syntax

```dockerfile
ARG <name>
ARG <name>=<default value>
```

### Multiple Forms

```dockerfile
# 1. ARG without default value
ARG VERSION

# 2. ARG with default value
ARG VERSION=1.0.0

# 3. Multiple ARGs
ARG NODE_VERSION=18
ARG APP_ENV=production
ARG BUILD_DATE

# 4. Using ARG values
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine
```

### Command Line Override

```bash
# Build with default ARG values
docker build -t myapp .

# Override single ARG
docker build --build-arg VERSION=2.0.0 -t myapp .

# Override multiple ARGs
docker build \
  --build-arg NODE_VERSION=20 \
  --build-arg APP_ENV=staging \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  -t myapp .
```

---

## How ARG Works

### Lifecycle of ARG

```dockerfile
# Stage 1: ARG before FROM (global scope)
ARG BASE_IMAGE=node:18-alpine

# Stage 2: FROM uses the ARG
FROM ${BASE_IMAGE}

# Stage 3: ARG in build stage (stage scope)
ARG APP_VERSION=1.0.0
ARG BUILD_DATE

# Stage 4: Using ARG in instructions
LABEL version="${APP_VERSION}" \
      build-date="${BUILD_DATE}"

RUN echo "Building version ${APP_VERSION}"

# Stage 5: ARG not available at runtime
# CMD will not have access to APP_VERSION
```

### Scope Rules

```dockerfile
# ❌ Wrong: ARG defined in one stage isn't available in another
FROM node:18 AS builder
ARG VERSION=1.0.0
RUN echo $VERSION  # ✅ Works

FROM node:18 AS runtime
RUN echo $VERSION  # ❌ Fails - VERSION not defined here

# ✅ Correct: Redefine ARG in each stage
FROM node:18 AS builder
ARG VERSION=1.0.0
RUN echo $VERSION  # ✅ Works

FROM node:18 AS runtime
ARG VERSION=1.0.0  # Redefine for this stage
RUN echo $VERSION  # ✅ Works
```

### Variable Expansion

```dockerfile
ARG VERSION=1.0.0
ARG FULL_VERSION=v${VERSION}
ARG IMAGE_NAME=myapp

# Using in FROM
FROM alpine:${VERSION}

# Using in RUN
RUN echo "Version: ${VERSION}" > /version.txt

# Using in ENV (ARG → ENV conversion)
ENV APP_VERSION=${VERSION}

# Using in LABEL
LABEL version="${VERSION}"

# Using in ADD/COPY (limited support)
ARG CONFIG_FILE=config.json
COPY ${CONFIG_FILE} /app/
```

---

## ARG vs ENV

### Understanding the Difference

```dockerfile
FROM node:18-alpine

# ARG: Build-time only
ARG BUILD_ENV=production
ARG API_KEY=default-key

# ENV: Runtime variable
ENV NODE_ENV=${BUILD_ENV}
ENV PORT=3000

# At build time:
# - BUILD_ENV available in RUN commands
# - API_KEY available in RUN commands
# - NODE_ENV available in RUN commands
# - PORT available in RUN commands

# At runtime (in container):
# - BUILD_ENV NOT available ❌
# - API_KEY NOT available ❌
# - NODE_ENV available ✅
# - PORT available ✅

RUN echo "Build ENV: ${BUILD_ENV}"     # ✅ Works during build
RUN echo "API Key: ${API_KEY}"         # ✅ Works during build
RUN echo "Node ENV: ${NODE_ENV}"       # ✅ Works during build

# Container runtime - only ENV available
CMD echo "Node ENV: ${NODE_ENV}" && \
    echo "Port: ${PORT}" && \
    node server.js
```

### When to Use Each

| Scenario | Use ARG | Use ENV |
|----------|---------|---------|
| Base image version | ✅ | ❌ |
| Build tool version | ✅ | ❌ |
| Conditional builds | ✅ | ❌ |
| Build flags/options | ✅ | ❌ |
| App configuration | ❌ | ✅ |
| Runtime ports | ❌ | ✅ |
| Database URLs | ❌ | ✅ |
| Feature flags | ❌ | ✅ |
| Both (convert ARG→ENV) | ✅ | ✅ |

### ARG to ENV Conversion Pattern

```dockerfile
# Pattern: Accept build-time ARG, convert to runtime ENV
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

ARG API_URL=https://api.example.com
ENV API_URL=${API_URL}

# Now available at both build AND runtime
RUN echo "Build-time NODE_ENV: ${NODE_ENV}"
CMD echo "Runtime NODE_ENV: ${NODE_ENV}" && node app.js
```

---

## Scope and Availability

### Global ARGs (Before FROM)

```dockerfile
# Global scope - available to all FROM instructions
ARG BASE_IMAGE=node:18-alpine
ARG ALPINE_VERSION=3.19

# Can use in any FROM
FROM ${BASE_IMAGE}

# ❌ NOT available in build stages unless redefined
RUN echo ${BASE_IMAGE}  # Empty or error

# ✅ Must redeclare to use in build stages
ARG BASE_IMAGE
RUN echo ${BASE_IMAGE}  # Now works
```

### Stage-Specific ARGs

```dockerfile
FROM node:18-alpine AS builder

# Only available in 'builder' stage
ARG BUILD_FLAGS="--production"
ARG NODE_OPTIONS="--max-old-space-size=4096"

RUN npm install ${BUILD_FLAGS}

# ---

FROM node:18-alpine AS runtime

# Different ARGs for runtime stage
ARG APP_PORT=3000
ARG ENABLE_MONITORING=true

ENV PORT=${APP_PORT}
EXPOSE ${APP_PORT}
```

### Multi-Stage ARG Sharing

```dockerfile
# Global ARG
ARG APP_VERSION=1.0.0

FROM node:18-alpine AS builder
# Redeclare to use in this stage
ARG APP_VERSION
RUN echo "Building version ${APP_VERSION}" > /build-version.txt

FROM node:18-alpine AS test
# Redeclare to use in this stage
ARG APP_VERSION
RUN echo "Testing version ${APP_VERSION}"

FROM node:18-alpine AS production
# Redeclare to use in this stage
ARG APP_VERSION
LABEL version="${APP_VERSION}"
COPY --from=builder /build-version.txt /app/
```

### ARG Availability Matrix

| Location | Before FROM | After FROM | Next Stage | Runtime |
|----------|-------------|------------|------------|---------|
| Global ARG | ✅ | ❌ (must redeclare) | ❌ (must redeclare) | ❌ |
| Stage ARG | ❌ | ✅ | ❌ | ❌ |
| ENV from ARG | ❌ | ✅ | ✅ | ✅ |

---

## Industry Standards & Best Practices

### 1. Always Provide Default Values

```dockerfile
# ❌ Bad: No default value
ARG VERSION

# ✅ Good: Default value provided
ARG VERSION=1.0.0

# ✅ Better: Semantic default
ARG NODE_VERSION=18.19.0
ARG ENVIRONMENT=production
ARG BUILD_DATE=unknown
```

### 2. Use Semantic Naming

```dockerfile
# ✅ Good naming conventions
ARG APP_VERSION=1.0.0          # Clear purpose
ARG NODE_ENV=production        # Standard name
ARG BUILD_TIMESTAMP            # Descriptive
ARG ENABLE_CACHE=true         # Boolean flag
ARG BASE_IMAGE_TAG=alpine     # Specific scope

# ❌ Bad naming
ARG V=1.0.0                   # Too short
ARG var1=something            # Not descriptive
ARG x=123                     # Meaningless
```

### 3. Document ARGs at Top of Dockerfile

```dockerfile
# =============================================================================
# Build Arguments
# =============================================================================
# Override at build time with: docker build --build-arg <name>=<value>
#
# APP_VERSION     : Application version tag (default: 1.0.0)
# NODE_VERSION    : Node.js version (default: 18)
# BUILD_ENV       : Build environment (default: production)
# ENABLE_CACHE    : Enable caching (default: true)
# =============================================================================

ARG APP_VERSION=1.0.0
ARG NODE_VERSION=18
ARG BUILD_ENV=production
ARG ENABLE_CACHE=true

FROM node:${NODE_VERSION}-alpine

# ... rest of Dockerfile
```

### 4. Group Related ARGs

```dockerfile
# Base Image Configuration
ARG BASE_IMAGE=node
ARG BASE_VERSION=18
ARG BASE_VARIANT=alpine

FROM ${BASE_IMAGE}:${BASE_VERSION}-${BASE_VARIANT}

# Build Configuration
ARG BUILD_ENV=production
ARG BUILD_FLAGS="--production --no-optional"
ARG ENABLE_TESTS=false

# Application Configuration
ARG APP_VERSION=1.0.0
ARG APP_PORT=3000
ARG LOG_LEVEL=info
```

### 5. Minimize ARG Usage for Cache Efficiency

```dockerfile
# ❌ Bad: ARG used early, busts cache often
FROM node:18-alpine
ARG BUILD_DATE
RUN echo "Build date: ${BUILD_DATE}"
COPY package*.json ./
RUN npm install  # Cache busted every time BUILD_DATE changes

# ✅ Good: ARG used late, preserves cache
FROM node:18-alpine
COPY package*.json ./
RUN npm install  # Cached unless package.json changes
ARG BUILD_DATE
RUN echo "Build date: ${BUILD_DATE}"
```

### 6. Use ARG for Platform-Specific Builds

```dockerfile
# Multi-architecture build support
ARG TARGETARCH
ARG TARGETOS
ARG TARGETPLATFORM

FROM --platform=${TARGETPLATFORM} alpine:latest

RUN echo "Building for ${TARGETOS}/${TARGETARCH}"

# Copy platform-specific binaries
COPY --chmod=755 binary-${TARGETOS}-${TARGETARCH} /usr/local/bin/app
```

### 7. Validate ARG Values

```dockerfile
ARG ENVIRONMENT=production

# Validate ENVIRONMENT is one of allowed values
RUN if [ "$ENVIRONMENT" != "development" ] && \
       [ "$ENVIRONMENT" != "staging" ] && \
       [ "$ENVIRONMENT" != "production" ]; then \
        echo "Error: ENVIRONMENT must be development, staging, or production" && \
        exit 1; \
    fi

RUN echo "Building for ${ENVIRONMENT} environment"
```

### 8. Use .dockerignore to Exclude Build Arg Files

```dockerfile
# .dockerignore
.env
.env.*
secrets/
*.key
*.pem
build-args.txt
```

### 9. Conditional Logic with ARGs

```dockerfile
ARG INSTALL_DEV_DEPS=false

# Conditional package installation
RUN if [ "$INSTALL_DEV_DEPS" = "true" ]; then \
        npm install --include=dev; \
    else \
        npm install --omit=dev; \
    fi

# Alternative: Use shell parameter expansion
RUN npm install ${INSTALL_DEV_DEPS:+--include=dev} ${INSTALL_DEV_DEPS:+}
```

### 10. Standardized Metadata ARGs

```dockerfile
# OCI/BuildKit standard build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.title="My Application" \
      org.opencontainers.image.description="Production application"
```

---

## Common Use Cases

### 1. Dynamic Base Image Selection

```dockerfile
# Allow flexible base image at build time
ARG BASE_IMAGE=node
ARG NODE_VERSION=18
ARG VARIANT=alpine

FROM ${BASE_IMAGE}:${NODE_VERSION}-${VARIANT}

WORKDIR /app
COPY package*.json ./
RUN npm install

# Build examples:
# docker build -t app:node18 .
# docker build --build-arg NODE_VERSION=20 -t app:node20 .
# docker build --build-arg VARIANT=slim -t app:slim .
# docker build --build-arg BASE_IMAGE=node --build-arg NODE_VERSION=16 -t app:node16 .
```

### 2. Version Management

```dockerfile
# Application versioning
ARG APP_VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_NUMBER=local

FROM golang:1.21-alpine AS builder

ARG APP_VERSION
ARG GIT_COMMIT
ARG BUILD_NUMBER

# Inject version into binary
RUN go build \
    -ldflags "-X main.Version=${APP_VERSION} \
              -X main.Commit=${GIT_COMMIT} \
              -X main.BuildNumber=${BUILD_NUMBER}" \
    -o /app/server ./cmd/server

FROM alpine:3.19
COPY --from=builder /app/server /usr/local/bin/

# Add to labels
LABEL version="${APP_VERSION}" \
      commit="${GIT_COMMIT}" \
      build="${BUILD_NUMBER}"

# Build:
# docker build \
#   --build-arg APP_VERSION=1.2.3 \
#   --build-arg GIT_COMMIT=$(git rev-parse --short HEAD) \
#   --build-arg BUILD_NUMBER=${CI_BUILD_NUMBER} \
#   -t app:1.2.3 .
```

### 3. Environment-Specific Builds

```dockerfile
ARG ENVIRONMENT=production
ARG API_URL
ARG FEATURE_FLAGS

FROM node:18-alpine

# Convert to ENV for runtime
ENV NODE_ENV=${ENVIRONMENT}
ENV REACT_APP_API_URL=${API_URL}
ENV REACT_APP_FEATURES=${FEATURE_FLAGS}

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .

# Environment-specific build optimizations
RUN if [ "$ENVIRONMENT" = "production" ]; then \
        npm run build:prod; \
    elif [ "$ENVIRONMENT" = "staging" ]; then \
        npm run build:staging; \
    else \
        npm run build:dev; \
    fi

# Build examples:
# Development:
# docker build --build-arg ENVIRONMENT=development -t app:dev .
#
# Staging:
# docker build \
#   --build-arg ENVIRONMENT=staging \
#   --build-arg API_URL=https://api.staging.example.com \
#   -t app:staging .
#
# Production:
# docker build \
#   --build-arg ENVIRONMENT=production \
#   --build-arg API_URL=https://api.example.com \
#   --build-arg FEATURE_FLAGS="feature1,feature2" \
#   -t app:prod .
```

### 4. Dependency Version Management

```dockerfile
# Control dependency versions
ARG PYTHON_VERSION=3.11
ARG POETRY_VERSION=1.7.1
ARG NODEJS_VERSION=18

FROM python:${PYTHON_VERSION}-slim AS base

# Install specific Poetry version
ARG POETRY_VERSION
RUN pip install "poetry==${POETRY_VERSION}"

# Install specific Node version (if needed)
ARG NODEJS_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --no-dev

# Build with different versions:
# docker build --build-arg PYTHON_VERSION=3.12 --build-arg POETRY_VERSION=1.8.0 -t app:py312 .
```

### 5. Conditional Feature Installation

```dockerfile
ARG INSTALL_POSTGRES=true
ARG INSTALL_REDIS=true
ARG INSTALL_MONITORING=false

FROM node:18-alpine

# Conditional PostgreSQL client
RUN if [ "$INSTALL_POSTGRES" = "true" ]; then \
        apk add --no-cache postgresql-client; \
    fi

# Conditional Redis client
RUN if [ "$INSTALL_REDIS" = "true" ]; then \
        apk add --no-cache redis; \
    fi

# Conditional monitoring tools
RUN if [ "$INSTALL_MONITORING" = "true" ]; then \
        apk add --no-cache curl htop; \
    fi

# Minimal build (nothing extra):
# docker build --build-arg INSTALL_POSTGRES=false --build-arg INSTALL_REDIS=false -t app:minimal .
#
# Full build (everything):
# docker build --build-arg INSTALL_MONITORING=true -t app:full .
```

### 6. Build Optimization Flags

```dockerfile
ARG ENABLE_CACHE=true
ARG PARALLEL_JOBS=4
ARG OPTIMIZATION_LEVEL=2

FROM gcc:12 AS builder

ARG ENABLE_CACHE
ARG PARALLEL_JOBS
ARG OPTIMIZATION_LEVEL

WORKDIR /src
COPY . .

# Configure build with ARGs
RUN ./configure \
    $([ "$ENABLE_CACHE" = "true" ] && echo "--enable-cache" || echo "--disable-cache") \
    --with-optimization=${OPTIMIZATION_LEVEL}

RUN make -j${PARALLEL_JOBS}
RUN make install

# Fast debug build:
# docker build --build-arg OPTIMIZATION_LEVEL=0 --build-arg ENABLE_CACHE=false -t app:debug .
#
# Optimized production build:
# docker build --build-arg OPTIMIZATION_LEVEL=3 --build-arg PARALLEL_JOBS=8 -t app:prod .
```

### 7. User and Permission Management

```dockerfile
ARG APP_USER=appuser
ARG APP_UID=1000
ARG APP_GID=1000

FROM node:18-alpine

ARG APP_USER
ARG APP_UID
ARG APP_GID

# Create user with specified UID/GID
RUN addgroup -g ${APP_GID} ${APP_USER} && \
    adduser -D -u ${APP_UID} -G ${APP_USER} ${APP_USER}

WORKDIR /app
COPY --chown=${APP_USER}:${APP_USER} . .

USER ${APP_USER}

# Custom UID/GID for enterprise environments:
# docker build --build-arg APP_UID=2000 --build-arg APP_GID=2000 -t app:custom .
```

### 8. Multi-Architecture Builds

```dockerfile
ARG TARGETARCH
ARG BUILDPLATFORM

FROM --platform=${BUILDPLATFORM} golang:1.21-alpine AS builder

ARG TARGETARCH
ARG TARGETOS

WORKDIR /src
COPY . .

# Cross-compile for target architecture
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /app/server

FROM alpine:3.19
COPY --from=builder /app/server /usr/local/bin/

# BuildKit automatically sets TARGETARCH and TARGETOS
# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t app:multi .
```

### 9. Proxy Configuration

```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

FROM ubuntu:22.04

# Set proxy for build-time operations
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV no_proxy=${NO_PROXY}

RUN apt-get update && apt-get install -y curl wget

# Unset proxy for runtime (optional)
ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

# Build behind corporate proxy:
# docker build \
#   --build-arg HTTP_PROXY=http://proxy.company.com:8080 \
#   --build-arg HTTPS_PROXY=http://proxy.company.com:8080 \
#   --build-arg NO_PROXY=localhost,127.0.0.1,.company.com \
#   -t app .
```

### 10. License and Compliance

```dockerfile
ARG LICENSE=MIT
ARG COMPLIANCE_LEVEL=standard
ARG SCAN_VULNERABILITIES=true

FROM node:18-alpine

ARG LICENSE
ARG COMPLIANCE_LEVEL
ARG SCAN_VULNERABILITIES

# Add license to image
COPY LICENSE /usr/share/doc/app/

# Compliance scanning
RUN if [ "$SCAN_VULNERABILITIES" = "true" ]; then \
        npm audit --audit-level=${COMPLIANCE_LEVEL}; \
    fi

LABEL license="${LICENSE}" \
      compliance="${COMPLIANCE_LEVEL}"

# Strict compliance build:
# docker build --build-arg COMPLIANCE_LEVEL=high --build-arg SCAN_VULNERABILITIES=true -t app:compliant .
```

---

## Security Considerations

### 1. ARGs Are Stored in Image History ⚠️

```dockerfile
# ❌ DANGER: Secret exposed in image history
ARG API_KEY=secret-key-12345
RUN curl -H "Authorization: ${API_KEY}" https://api.example.com/data > /data.json

# Even though API_KEY isn't in ENV, it's visible in:
# docker history myimage
# docker image inspect myimage
```

**Check what's exposed:**

```bash
# See ARG values in history
docker history myimage --no-trunc

# See ARG values in inspect
docker image inspect myimage | grep -A 10 ContainerConfig
```

### 2. Never Use ARG for Secrets ❌

```dockerfile
# ❌ BAD: Secrets in ARG
ARG DATABASE_PASSWORD=mypassword
ARG API_TOKEN=token-123
ARG PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."

ENV DB_PASS=${DATABASE_PASSWORD}  # Now in image AND history!

# ✅ GOOD: Use BuildKit secrets instead
FROM node:18-alpine

RUN --mount=type=secret,id=db_password \
    --mount=type=secret,id=api_token \
    DB_PASS=$(cat /run/secrets/db_password) \
    API_TOKEN=$(cat /run/secrets/api_token) \
    npm run setup

# Build with secrets (not stored in image):
# docker build --secret id=db_password,src=./secrets/db.txt -t app .
```

### 3. Use Docker BuildKit Secrets

```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:18-alpine

# ✅ Secure: Secret mounted, not stored in image
RUN --mount=type=secret,id=npm_token \
    echo "//registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token)" > ~/.npmrc && \
    npm install && \
    rm ~/.npmrc

# Build:
# DOCKER_BUILDKIT=1 docker build --secret id=npm_token,src=$HOME/.npmrc -t app .
```

### 4. SSH Keys During Build

```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:18-alpine

# ✅ Secure: SSH key mounted, not copied
RUN --mount=type=ssh \
    git clone git@github.com:company/private-repo.git /app

# Build:
# DOCKER_BUILDKIT=1 docker build --ssh default -t app .
```

### 5. Sensitive ARGs - Minimizing Exposure

```dockerfile
# If you MUST use ARG for somewhat sensitive data:

# 1. Use it late in Dockerfile (minimize cache busting)
# 2. Don't convert to ENV
# 3. Use in single RUN command
# 4. Clear after use

ARG BUILD_TOKEN

# ✅ Use and clear in single layer
RUN --mount=type=secret,id=build_token,required=true \
    BUILD_TOKEN=$(cat /run/secrets/build_token) && \
    curl -H "Authorization: Bearer ${BUILD_TOKEN}" https://api.example.com/data > /data.json && \
    unset BUILD_TOKEN

# Better: Use BuildKit secrets (above)
```

### 6. Validation and Sanitization

```dockerfile
ARG USER_INPUT

# ✅ Validate input to prevent injection
RUN if ! echo "${USER_INPUT}" | grep -qE '^[a-zA-Z0-9_-]+$'; then \
        echo "Error: USER_INPUT contains invalid characters" && \
        exit 1; \
    fi

RUN echo "Safe input: ${USER_INPUT}"
```

### 7. Limit ARG Scope

```dockerfile
# ❌ Bad: ARG available everywhere
ARG SENSITIVE_CONFIG=value
FROM node:18-alpine
RUN echo ${SENSITIVE_CONFIG}
RUN npm install
RUN build-app
# ... many more layers with potential leaks

# ✅ Good: Limit ARG scope to where needed
FROM node:18-alpine
COPY package*.json ./
RUN npm install

# Only introduce ARG when needed
ARG SENSITIVE_CONFIG
RUN use-config ${SENSITIVE_CONFIG} && \
    rm -rf /tmp/*
```

### 8. Audit Build Arguments

```dockerfile
# Document expected ARGs at top
# =============================================================================
# ⚠️  Security: Review ARG values before building
# =============================================================================
# SAFE ARGs (non-sensitive):
ARG APP_VERSION=1.0.0        # ✅ Safe
ARG NODE_VERSION=18          # ✅ Safe
ARG ENVIRONMENT=production   # ✅ Safe

# SENSITIVE ARGs (use secrets instead):
# ARG API_KEY               # ❌ Use --secret instead
# ARG DATABASE_PASSWORD     # ❌ Use --secret instead
# ARG PRIVATE_KEY           # ❌ Use --secret instead
```

### 9. Scanning for Exposed Secrets

```bash
# Scan image history for potential secrets
docker history myimage --no-trunc | grep -i "password\|secret\|key\|token"

# Scan image with dedicated tools
trivy image myimage
grype myimage
```

### 10. Best Practices Summary

| Practice | Status | Reason |
|----------|--------|--------|
| ARG for version numbers | ✅ Safe | Non-sensitive |
| ARG for environment names | ✅ Safe | Non-sensitive |
| ARG for build flags | ✅ Safe | Non-sensitive |
| ARG for passwords | ❌ Unsafe | Stored in history |
| ARG for API keys | ❌ Unsafe | Stored in history |
| ARG for tokens | ❌ Unsafe | Stored in history |
| ARG for certificates | ❌ Unsafe | Stored in history |
| BuildKit --secret | ✅ Safe | Not stored |
| BuildKit --ssh | ✅ Safe | Not stored |

---

## Multi-Stage Builds with ARG

### Pattern 1: Shared ARGs Across Stages

```dockerfile
# Define global ARGs before FROM
ARG APP_VERSION=1.0.0
ARG NODE_VERSION=18

# ===== Build Stage =====
FROM node:${NODE_VERSION}-alpine AS builder

# Redeclare to use in this stage
ARG APP_VERSION
ARG BUILD_ENV=production

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Store version in build artifact
RUN echo "${APP_VERSION}" > /app/dist/version.txt

# ===== Test Stage =====
FROM builder AS test

# Redeclare ARGs needed here
ARG APP_VERSION

RUN npm run test
RUN npm run lint

# ===== Production Stage =====
FROM node:${NODE_VERSION}-alpine AS production

# Redeclare for final stage
ARG APP_VERSION
ARG NODE_VERSION

LABEL version="${APP_VERSION}" \
      node-version="${NODE_VERSION}"

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

ENV APP_VERSION=${APP_VERSION}

USER node
CMD ["node", "dist/server.js"]
```

### Pattern 2: Stage-Specific ARGs

```dockerfile
FROM node:18-alpine AS builder

# Builder-specific ARGs
ARG BUILD_PARALLELISM=4
ARG ENABLE_CACHE=true
ARG WEBPACK_MODE=production

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build -- \
    --mode ${WEBPACK_MODE} \
    --cache ${ENABLE_CACHE} \
    --parallelism ${BUILD_PARALLELISM}

# ===== Runtime Stage =====
FROM node:18-alpine AS runtime

# Runtime-specific ARGs
ARG APP_PORT=3000
ARG WORKER_THREADS=4
ARG LOG_LEVEL=info

# Convert to ENV for runtime
ENV PORT=${APP_PORT}
ENV WORKERS=${WORKER_THREADS}
ENV LOG_LEVEL=${LOG_LEVEL}

WORKDIR /app
COPY --from=builder /app/dist ./

EXPOSE ${APP_PORT}
CMD ["node", "server.js"]

# Build example:
# docker build \
#   --build-arg BUILD_PARALLELISM=8 \
#   --build-arg ENABLE_CACHE=false \
#   --build-arg APP_PORT=8080 \
#   --target runtime \
#   -t app:prod .
```

### Pattern 3: Conditional Stage Selection

```dockerfile
ARG BUILD_TARGET=production

# ===== Development Stage =====
FROM node:18-alpine AS development

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .

CMD ["npm", "run", "dev"]

# ===== Production Builder =====
FROM node:18-alpine AS production-builder

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

COPY . .
RUN npm run build

# ===== Production Stage =====
FROM node:18-alpine AS production

WORKDIR /app
COPY --from=production-builder /app/dist ./dist
COPY --from=production-builder /app/node_modules ./node_modules

CMD ["node", "dist/server.js"]

# ===== Final Stage (selected by ARG) =====
FROM ${BUILD_TARGET} AS final

# Build commands:
# Development: docker build --build-arg BUILD_TARGET=development -t app:dev .
# Production:  docker build --build-arg BUILD_TARGET=production -t app:prod .
```

### Pattern 4: Build Matrix

```dockerfile
ARG GO_VERSION=1.21
ARG ALPINE_VERSION=3.19
ARG CGO_ENABLED=0

# ===== Builder Stage =====
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG CGO_ENABLED
ARG GOOS=linux
ARG GOARCH=amd64

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=${CGO_ENABLED} GOOS=${GOOS} GOARCH=${GOARCH} \
    go build -ldflags="-w -s" -o /app/server ./cmd/server

# ===== Runtime Stage =====
FROM alpine:${ALPINE_VERSION}

ARG APP_USER=appuser

RUN addgroup -g 1000 ${APP_USER} && \
    adduser -D -u 1000 -G ${APP_USER} ${APP_USER}

COPY --from=builder /app/server /usr/local/bin/
USER ${APP_USER}

CMD ["server"]

# Build matrix examples:
# Go 1.21 + Alpine 3.19:
# docker build --build-arg GO_VERSION=1.21 --build-arg ALPINE_VERSION=3.19 -t app:go1.21 .
#
# Go 1.22 + Alpine 3.19:
# docker build --build-arg GO_VERSION=1.22 --build-arg ALPINE_VERSION=3.19 -t app:go1.22 .
#
# With CGO:
# docker build --build-arg CGO_ENABLED=1 -t app:cgo .
```

### Pattern 5: Parallel Build Stages

```dockerfile
ARG NODE_VERSION=18

FROM node:${NODE_VERSION}-alpine AS dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci

# ===== Frontend Build =====
FROM dependencies AS frontend-builder

ARG FRONTEND_API_URL=https://api.example.com

COPY frontend ./frontend
WORKDIR /app/frontend
RUN REACT_APP_API_URL=${FRONTEND_API_URL} npm run build

# ===== Backend Build =====
FROM dependencies AS backend-builder

ARG BACKEND_PORT=3000

COPY backend ./backend
WORKDIR /app/backend
RUN npm run build

# ===== Final Stage =====
FROM node:${NODE_VERSION}-alpine

ARG BACKEND_PORT=3000
ENV PORT=${BACKEND_PORT}

WORKDIR /app

# Copy both frontend and backend builds
COPY --from=frontend-builder /app/frontend/build ./public
COPY --from=backend-builder /app/backend/dist ./dist
COPY --from=backend-builder /app/backend/node_modules ./node_modules

EXPOSE ${BACKEND_PORT}
CMD ["node", "dist/server.js"]

# Build:
# docker build \
#   --build-arg FRONTEND_API_URL=https://api.prod.example.com \
#   --build-arg BACKEND_PORT=8080 \
#   -t fullstack-app .
```

---

## Advanced Patterns

### 1. Dynamic Dockerfile Generation

```dockerfile
ARG TEMPLATE=basic

# ===== Template: Basic =====
FROM node:18-alpine AS basic

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "start"]

# ===== Template: Advanced =====
FROM node:18-alpine AS advanced

# Install additional tools
RUN apk add --no-cache curl jq

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]

# ===== Template: Optimized =====
FROM node:18-alpine AS optimized-builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build

FROM node:18-alpine AS optimized
WORKDIR /app
COPY --from=optimized-builder /app/dist ./
CMD ["node", "index.js"]

# ===== Final Selection =====
FROM ${TEMPLATE} AS final

# Build examples:
# docker build --build-arg TEMPLATE=basic -t app:basic .
# docker build --build-arg TEMPLATE=advanced -t app:advanced .
# docker build --build-arg TEMPLATE=optimized -t app:optimized .
```

### 2. Feature Flags

```dockerfile
ARG ENABLE_REDIS=false
ARG ENABLE_POSTGRES=false
ARG ENABLE_MONITORING=false
ARG ENABLE_DEBUG=false

FROM node:18-alpine

# Install features based on flags
RUN apk add --no-cache \
    $([ "$ENABLE_REDIS" = "true" ] && echo "redis") \
    $([ "$ENABLE_POSTGRES" = "true" ] && echo "postgresql-client") \
    $([ "$ENABLE_MONITORING" = "true" ] && echo "curl htop") \
    $([ "$ENABLE_DEBUG" = "true" ] && echo "bash vim strace")

WORKDIR /app
COPY . .

# Set ENV based on features
ENV REDIS_ENABLED=${ENABLE_REDIS}
ENV POSTGRES_ENABLED=${ENABLE_POSTGRES}
ENV MONITORING_ENABLED=${ENABLE_MONITORING}
ENV DEBUG_MODE=${ENABLE_DEBUG}

CMD ["node", "server.js"]

# Minimal build:
# docker build -t app:minimal .
#
# Full featured build:
# docker build \
#   --build-arg ENABLE_REDIS=true \
#   --build-arg ENABLE_POSTGRES=true \
#   --build-arg ENABLE_MONITORING=true \
#   -t app:full .
```

### 3. Build Configuration Matrix

```dockerfile
ARG ENVIRONMENT=production
ARG REGION=us-east-1
ARG CUSTOMER=default

FROM node:18-alpine

# Load environment-specific configs
COPY config/base.json /app/config/
COPY config/${ENVIRONMENT}.json /app/config/
COPY config/${REGION}.json /app/config/
COPY config/customers/${CUSTOMER}.json /app/config/

RUN node scripts/merge-config.js \
    /app/config/base.json \
    /app/config/${ENVIRONMENT}.json \
    /app/config/${REGION}.json \
    /app/config/customers/${CUSTOMER}.json \
    > /app/config/final.json

# Build for different combinations:
# docker build --build-arg ENVIRONMENT=staging --build-arg REGION=eu-west-1 -t app:staging-eu .
# docker build --build-arg ENVIRONMENT=production --build-arg CUSTOMER=acme -t app:prod-acme .
```

### 4. Computed Values

```dockerfile
ARG BASE_VERSION=1.0.0
ARG BUILD_NUMBER=1
ARG BRANCH=main

# Compute semantic version
ARG VERSION=${BASE_VERSION}-${BUILD_NUMBER}
ARG FULL_VERSION=${VERSION}+${BRANCH}

FROM node:18-alpine

ARG FULL_VERSION

LABEL version="${FULL_VERSION}"

RUN echo "${FULL_VERSION}" > /app/version.txt

ENV APP_VERSION=${FULL_VERSION}

# Build:
# docker build \
#   --build-arg BASE_VERSION=1.2.3 \
#   --build-arg BUILD_NUMBER=456 \
#   --build-arg BRANCH=feature-x \
#   -t app:1.2.3-456+feature-x .
```

### 5. Layered Configuration

```dockerfile
# Layer 1: Base configuration
ARG BASE_IMAGE=node
ARG BASE_VERSION=18
ARG BASE_VARIANT=alpine

# Layer 2: Build configuration
ARG BUILD_TOOLS="git curl"
ARG BUILD_OPTS="--production"

# Layer 3: Runtime configuration
ARG RUNTIME_PACKAGES="ca-certificates"
ARG RUNTIME_USER=appuser

FROM ${BASE_IMAGE}:${BASE_VERSION}-${BASE_VARIANT}

# Apply layered configuration
RUN apk add --no-cache ${BUILD_TOOLS}
RUN apk add --no-cache ${RUNTIME_PACKAGES}

WORKDIR /app
COPY package*.json ./
RUN npm install ${BUILD_OPTS}

RUN adduser -D ${RUNTIME_USER}
USER ${RUNTIME_USER}

CMD ["node", "server.js"]
```

### 6. Cross-Platform Builds

```dockerfile
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

FROM --platform=${TARGETPLATFORM} golang:1.21-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /src
COPY . .

# Build for specific platform
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT#v} \
    go build -o /app/server

FROM --platform=${TARGETPLATFORM} alpine:3.19

ARG TARGETPLATFORM
LABEL platform="${TARGETPLATFORM}"

COPY --from=builder /app/server /usr/local/bin/

CMD ["server"]

# Build multi-platform:
# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t app:multi .
```

### 7. Build Cache Optimization

```dockerfile
ARG CACHE_BUST

FROM node:18-alpine

# Cached layers (no ARG)
COPY package*.json ./
RUN npm install

# Cached layers (no ARG)
COPY src ./src

# Cache-busting layer (ARG used)
ARG CACHE_BUST
RUN echo "Cache bust: ${CACHE_BUST}"

# Layers after this will rebuild
COPY . .
RUN npm run build

# Rebuild only final layers:
# docker build --build-arg CACHE_BUST=$(date +%s) -t app .
```

### 8. Composite Build Arguments

```dockerfile
ARG REGISTRY=docker.io
ARG NAMESPACE=library
ARG IMAGE=node
ARG TAG=18-alpine

# Compose full image reference
ARG FULL_IMAGE=${REGISTRY}/${NAMESPACE}/${IMAGE}:${TAG}

FROM ${FULL_IMAGE}

ARG FULL_IMAGE
LABEL base-image="${FULL_IMAGE}"

# Build from different registries:
# docker build --build-arg REGISTRY=gcr.io --build-arg NAMESPACE=my-project -t app .
# docker build --build-arg REGISTRY=my-registry.com --build-arg NAMESPACE=team -t app .
```

### 9. Build Metadata Injection

```dockerfile
ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GIT_TAG
ARG CI_BUILD_URL
ARG CI_BUILD_NUMBER

FROM node:18-alpine

ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GIT_TAG
ARG CI_BUILD_URL
ARG CI_BUILD_NUMBER

# Inject metadata into application
RUN echo "{\
  \"buildDate\": \"${BUILD_DATE}\",\
  \"commit\": \"${GIT_COMMIT}\",\
  \"branch\": \"${GIT_BRANCH}\",\
  \"tag\": \"${GIT_TAG}\",\
  \"buildUrl\": \"${CI_BUILD_URL}\",\
  \"buildNumber\": \"${CI_BUILD_NUMBER}\"\
}" > /app/build-info.json

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.source="${CI_BUILD_URL}"

# Build in CI:
# docker build \
#   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
#   --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
#   --build-arg GIT_BRANCH=$(git branch --show-current) \
#   --build-arg GIT_TAG=$(git describe --tags --always) \
#   --build-arg CI_BUILD_URL=${CI_JOB_URL} \
#   --build-arg CI_BUILD_NUMBER=${CI_BUILD_NUMBER} \
#   -t app .
```

### 10. Parameterized Healthchecks

```dockerfile
ARG HEALTHCHECK_ENDPOINT=/health
ARG HEALTHCHECK_INTERVAL=30s
ARG HEALTHCHECK_TIMEOUT=3s
ARG HEALTHCHECK_RETRIES=3

FROM node:18-alpine

ARG HEALTHCHECK_ENDPOINT
ARG HEALTHCHECK_INTERVAL
ARG HEALTHCHECK_TIMEOUT
ARG HEALTHCHECK_RETRIES

WORKDIR /app
COPY . .

# Dynamic healthcheck configuration
HEALTHCHECK \
  --interval=${HEALTHCHECK_INTERVAL} \
  --timeout=${HEALTHCHECK_TIMEOUT} \
  --retries=${HEALTHCHECK_RETRIES} \
  CMD curl -f http://localhost:3000${HEALTHCHECK_ENDPOINT} || exit 1

CMD ["node", "server.js"]

# Custom healthcheck:
# docker build --build-arg HEALTHCHECK_ENDPOINT=/api/status --build-arg HEALTHCHECK_INTERVAL=10s -t app .
```

---

## Real-World Examples

### Example 1: Node.js Microservice

```dockerfile
# =============================================================================
# Node.js Microservice - Production-Ready Dockerfile with ARGs
# =============================================================================

# Build arguments
ARG NODE_VERSION=18.19.0
ARG ALPINE_VERSION=3.19
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG GIT_COMMIT

# ===== Dependencies Stage =====
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS dependencies

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY package-lock.json ./

# Install ALL dependencies (including dev)
RUN npm ci

# ===== Build Stage =====
FROM dependencies AS builder

ARG APP_VERSION
ARG BUILD_DATE
ARG GIT_COMMIT

# Copy source code
COPY . .

# Build application with version info
RUN npm run build

# Inject build metadata
RUN echo "{\
  \"version\": \"${APP_VERSION}\",\
  \"buildDate\": \"${BUILD_DATE}\",\
  \"commit\": \"${GIT_COMMIT}\"\
}" > /app/dist/build-info.json

# ===== Production Dependencies =====
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS prod-dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts

# ===== Production Stage =====
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS production

ARG APP_VERSION
ARG NODE_VERSION
ARG BUILD_DATE
ARG GIT_COMMIT

# Add metadata
LABEL org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="Microservice API" \
      org.opencontainers.image.description="Production Node.js microservice"

# Install production utilities
RUN apk add --no-cache \
    dumb-init \
    curl

# Create non-root user
RUN addgroup -g 1000 nodejs && \
    adduser -D -u 1000 -G nodejs nodejs

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=prod-dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]

# Build command:
# docker build \
#   --build-arg NODE_VERSION=18.19.0 \
#   --build-arg APP_VERSION=1.2.3 \
#   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
#   --build-arg GIT_COMMIT=$(git rev-parse --short HEAD) \
#   -t microservice:1.2.3 \
#   -t microservice:latest \
#   .
```

### Example 2: Python Flask Application

```dockerfile
# =============================================================================
# Python Flask Application with ARG Configuration
# =============================================================================

ARG PYTHON_VERSION=3.11
ARG POETRY_VERSION=1.7.1
ARG APP_VERSION=1.0.0

# ===== Builder Stage =====
FROM python:${PYTHON_VERSION}-slim AS builder

ARG POETRY_VERSION
ARG BUILD_ENV=production

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install "poetry==${POETRY_VERSION}"

WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies
RUN if [ "$BUILD_ENV" = "production" ]; then \
        poetry install --only main --no-root; \
    else \
        poetry install --no-root; \
    fi

# Copy application code
COPY . .

# Install application
RUN poetry build && \
    pip install dist/*.whl

# ===== Runtime Stage =====
FROM python:${PYTHON_VERSION}-slim AS runtime

ARG APP_VERSION
ARG PYTHON_VERSION

LABEL version="${APP_VERSION}" \
      python="${PYTHON_VERSION}"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy installed packages
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app ./

# Switch to non-root user
USER appuser

ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]

# Build:
# docker build \
#   --build-arg PYTHON_VERSION=3.11 \
#   --build-arg POETRY_VERSION=1.7.1 \
#   --build-arg APP_VERSION=2.0.0 \
#   --build-arg BUILD_ENV=production \
#   -t flask-app:2.0.0 .
```

### Example 3: Go Multi-Architecture Binary

```dockerfile
# =============================================================================
# Go Multi-Architecture Application
# =============================================================================

ARG GO_VERSION=1.21
ARG ALPINE_VERSION=3.19
ARG APP_VERSION=1.0.0

# ===== Builder Stage =====
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG APP_VERSION
ARG GIT_COMMIT
ARG BUILD_DATE
ARG TARGETOS
ARG TARGETARCH

# Install build dependencies
RUN apk add --no-cache git make

WORKDIR /src

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build with version information
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build \
    -ldflags="-w -s \
      -X main.Version=${APP_VERSION} \
      -X main.Commit=${GIT_COMMIT} \
      -X main.BuildDate=${BUILD_DATE}" \
    -o /app/server \
    ./cmd/server

# ===== Runtime Stage =====
FROM alpine:${ALPINE_VERSION}

ARG APP_VERSION
ARG ALPINE_VERSION

LABEL version="${APP_VERSION}" \
      alpine="${ALPINE_VERSION}"

# Install CA certificates for HTTPS
RUN apk add --no-cache ca-certificates

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

WORKDIR /app

# Copy binary
COPY --from=builder --chown=appuser:appgroup /app/server /usr/local/bin/

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s CMD ["/usr/local/bin/server", "health"] || exit 1

ENTRYPOINT ["/usr/local/bin/server"]
CMD ["serve"]

# Multi-arch build:
# docker buildx build \
#   --platform linux/amd64,linux/arm64,linux/arm/v7 \
#   --build-arg APP_VERSION=1.2.3 \
#   --build-arg GIT_COMMIT=$(git rev-parse --short HEAD) \
#   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
#   -t go-app:1.2.3 \
#   --push \
#   .
```

### Example 4: React Frontend with Nginx

```dockerfile
# =============================================================================
# React Frontend with Nginx
# =============================================================================

ARG NODE_VERSION=18
ARG NGINX_VERSION=1.25

# ===== Build Stage =====
FROM node:${NODE_VERSION}-alpine AS builder

ARG REACT_APP_API_URL=https://api.example.com
ARG REACT_APP_ENV=production
ARG REACT_APP_VERSION=1.0.0
ARG GENERATE_SOURCEMAP=false

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# Build with environment variables
ENV REACT_APP_API_URL=${REACT_APP_API_URL}
ENV REACT_APP_ENV=${REACT_APP_ENV}
ENV REACT_APP_VERSION=${REACT_APP_VERSION}
ENV GENERATE_SOURCEMAP=${GENERATE_SOURCEMAP}

RUN npm run build

# ===== Nginx Stage =====
FROM nginx:${NGINX_VERSION}-alpine

ARG REACT_APP_VERSION
ARG NGINX_VERSION

LABEL version="${REACT_APP_VERSION}" \
      nginx="${NGINX_VERSION}"

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# Add runtime configuration script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

# Build for different environments:
# Development:
# docker build \
#   --build-arg REACT_APP_API_URL=http://localhost:3001 \
#   --build-arg REACT_APP_ENV=development \
#   --build-arg GENERATE_SOURCEMAP=true \
#   -t react-app:dev .
#
# Production:
# docker build \
#   --build-arg REACT_APP_API_URL=https://api.prod.example.com \
#   --build-arg REACT_APP_ENV=production \
#   --build-arg REACT_APP_VERSION=2.1.0 \
#   -t react-app:2.1.0 .
```

### Example 5: Full-Stack Application

```dockerfile
# =============================================================================
# Full-Stack Application (Frontend + Backend)
# =============================================================================

ARG NODE_VERSION=18
ARG APP_VERSION=1.0.0
ARG BUILD_ENV=production

# ===== Frontend Build =====
FROM node:${NODE_VERSION}-alpine AS frontend-builder

ARG BUILD_ENV
ARG FRONTEND_API_URL

WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend ./

# Build frontend
ENV REACT_APP_API_URL=${FRONTEND_API_URL}
ENV NODE_ENV=${BUILD_ENV}

RUN npm run build

# ===== Backend Build =====
FROM node:${NODE_VERSION}-alpine AS backend-builder

ARG BUILD_ENV

WORKDIR /app/backend

COPY backend/package*.json ./
RUN npm ci

COPY backend ./

# Build backend (TypeScript)
RUN npm run build

# ===== Production =====
FROM node:${NODE_VERSION}-alpine AS production

ARG APP_VERSION
ARG NODE_VERSION

LABEL version="${APP_VERSION}" \
      node="${NODE_VERSION}" \
      type="fullstack"

# Install production dependencies for backend
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm ci --omit=dev

# Install nginx for serving frontend
RUN apk add --no-cache nginx

# Copy frontend build to nginx
COPY --from=frontend-builder /app/frontend/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

# Copy backend build
COPY --from=backend-builder /app/backend/dist ./dist

# Create startup script
COPY <<EOF /start.sh
#!/bin/sh
nginx
exec node dist/server.js
EOF

RUN chmod +x /start.sh

EXPOSE 80 3000

HEALTHCHECK --interval=30s CMD \
  wget -q --spider http://localhost/ && \
  wget -q --spider http://localhost:3000/health || exit 1

CMD ["/start.sh"]

# Build:
# docker build \
#   --build-arg APP_VERSION=1.5.0 \
#   --build-arg BUILD_ENV=production \
#   --build-arg FRONTEND_API_URL=https://api.example.com \
#   -t fullstack-app:1.5.0 .
```

---

## Predefined ARGs

Docker provides several predefined `ARG` variables that are automatically available in your Dockerfile.

### BuildKit Platform ARGs

These ARGs are automatically set by BuildKit during multi-platform builds:

```dockerfile
# Automatically available (no need to declare)
# - TARGETPLATFORM: Target platform (e.g., linux/amd64, linux/arm64)
# - TARGETOS: Target OS (e.g., linux, windows)
# - TARGETARCH: Target architecture (e.g., amd64, arm64, arm)
# - TARGETVARIANT: Architecture variant (e.g., v7, v8)
# - BUILDPLATFORM: Platform of build machine
# - BUILDOS: OS of build machine
# - BUILDARCH: Architecture of build machine
# - BUILDVARIANT: Architecture variant of build machine

# Using predefined ARGs
FROM --platform=${BUILDPLATFORM} golang:1.21 AS builder

# Must declare to use
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

RUN echo "Building for ${TARGETOS}/${TARGETARCH}${TARGETVARIANT}"

# Cross-compile
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /app/server

FROM alpine:3.19
ARG TARGETPLATFORM
LABEL platform="${TARGETPLATFORM}"
COPY --from=builder /app/server /usr/local/bin/
```

### HTTP/HTTPS Proxy ARGs

```dockerfile
# Automatically available (if set on host or via --build-arg)
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG FTP_PROXY
ARG NO_PROXY

# Lowercase versions
ARG http_proxy
ARG https_proxy
ARG ftp_proxy
ARG no_proxy

FROM ubuntu:22.04

# Proxy ARGs are automatically passed through
RUN apt-get update && apt-get install -y curl

# Build with proxy:
# docker build \
#   --build-arg HTTP_PROXY=http://proxy.company.com:8080 \
#   --build-arg HTTPS_PROXY=http://proxy.company.com:8080 \
#   --build-arg NO_PROXY=localhost,127.0.0.1 \
#   -t app .
```

### Complete Predefined ARGs Reference

| ARG | Description | Example Value |
|-----|-------------|---------------|
| `TARGETPLATFORM` | Full target platform | `linux/amd64` |
| `TARGETOS` | Target operating system | `linux` |
| `TARGETARCH` | Target architecture | `amd64` |
| `TARGETVARIANT` | Architecture variant | `v7` |
| `BUILDPLATFORM` | Builder's platform | `linux/amd64` |
| `BUILDOS` | Builder's OS | `linux` |
| `BUILDARCH` | Builder's architecture | `amd64` |
| `BUILDVARIANT` | Builder's variant | `v8` |
| `HTTP_PROXY` | HTTP proxy URL | `http://proxy:8080` |
| `http_proxy` | HTTP proxy (lowercase) | `http://proxy:8080` |
| `HTTPS_PROXY` | HTTPS proxy URL | `http://proxy:8080` |
| `https_proxy` | HTTPS proxy (lowercase) | `http://proxy:8080` |
| `FTP_PROXY` | FTP proxy URL | `http://proxy:8080` |
| `ftp_proxy` | FTP proxy (lowercase) | `http://proxy:8080` |
| `NO_PROXY` | No proxy hosts | `localhost,.company.com` |
| `no_proxy` | No proxy (lowercase) | `localhost,.company.com` |

### Using Predefined ARGs Example

```dockerfile
# =============================================================================
# Using All Predefined ARGs
# =============================================================================

# Build platform ARGs (must declare to use)
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH

# Use build platform for faster dependency downloads
FROM --platform=${BUILDPLATFORM} golang:1.21-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM

RUN echo "Build platform: ${BUILDPLATFORM}"
RUN echo "Target platform: ${TARGETPLATFORM}"
RUN echo "Building on: ${BUILDOS}/${BUILDARCH}"
RUN echo "Building for: ${TARGETOS}/${TARGETARCH}${TARGETVARIANT}"

WORKDIR /src
COPY . .

# Cross-compile for target platform
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOARM=${TARGETVARIANT#v} \
    go build -o /app/server

# Runtime stage
FROM --platform=${TARGETPLATFORM} alpine:3.19

ARG TARGETPLATFORM
LABEL platform="${TARGETPLATFORM}"

COPY --from=builder /app/server /usr/local/bin/
CMD ["server"]

# Multi-platform build:
# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t app .
```

---

## Common Mistakes

### 1. ❌ Using ARG Without Default Value

```dockerfile
# ❌ Bad: No default value
ARG VERSION
FROM node:${VERSION}  # Fails if not provided

# ✅ Good: Default value provided
ARG VERSION=18
FROM node:${VERSION}
```

### 2. ❌ Not Redeclaring ARG in Multi-Stage

```dockerfile
ARG VERSION=1.0.0

FROM node:18 AS builder
# ❌ VERSION not available here
RUN echo ${VERSION}  # Empty!

# ✅ Must redeclare
ARG VERSION
RUN echo ${VERSION}  # Now works
```

### 3. ❌ Using ARG for Secrets

```dockerfile
# ❌ Terrible: Secret in image history
ARG DATABASE_PASSWORD=secret123
ENV DB_PASS=${DATABASE_PASSWORD}

# ✅ Good: Use BuildKit secrets
RUN --mount=type=secret,id=db_pass \
    export DB_PASS=$(cat /run/secrets/db_pass)
```

### 4. ❌ ARG in Wrong Position (Cache Busting)

```dockerfile
# ❌ Bad: ARG at top, busts cache always
FROM node:18
ARG BUILD_DATE=$(date)  # Cache busted every time
COPY package*.json ./
RUN npm install  # Always rebuilds!

# ✅ Good: ARG at end, preserves cache
FROM node:18
COPY package*.json ./
RUN npm install  # Cached unless files change
ARG BUILD_DATE
LABEL build-date="${BUILD_DATE}"
```

### 5. ❌ Confusing ARG with ENV

```dockerfile
# ❌ Wrong: Using ARG for runtime config
ARG DATABASE_URL=postgres://localhost
CMD node server.js  # DATABASE_URL not available!

# ✅ Correct: Use ENV for runtime
ENV DATABASE_URL=postgres://localhost
CMD node server.js  # DATABASE_URL available

# ✅ Or: Convert ARG to ENV
ARG DATABASE_URL=postgres://localhost
ENV DATABASE_URL=${DATABASE_URL}
```

### 6. ❌ Not Quoting ARG with Spaces

```dockerfile
# ❌ Bad: Spaces cause issues
ARG MESSAGE=Hello World
RUN echo ${MESSAGE}  # Only echoes "Hello"

# ✅ Good: Quote values with spaces
ARG MESSAGE="Hello World"
RUN echo "${MESSAGE}"  # Echoes "Hello World"
```

### 7. ❌ Using ARG Before FROM Without Redeclaring

```dockerfile
ARG BASE_VERSION=18

FROM node:${BASE_VERSION}  # ✅ Works

# ❌ Doesn't work - not available after FROM
RUN echo ${BASE_VERSION}  # Empty!

# ✅ Must redeclare
ARG BASE_VERSION
RUN echo ${BASE_VERSION}  # Now works
```

### 8. ❌ Expecting ARG in Running Container

```dockerfile
ARG APP_PORT=3000
FROM node:18

# ✅ Works during build
RUN echo "Port: ${APP_PORT}"

# ❌ Doesn't work at runtime
CMD echo "Port: ${APP_PORT}" && node server.js
# APP_PORT is empty at runtime!

# ✅ Convert to ENV
ENV PORT=${APP_PORT}
CMD echo "Port: ${PORT}" && node server.js
```

### 9. ❌ Overusing ARGs

```dockerfile
# ❌ Bad: Too many ARGs, hard to use
ARG VAR1 VAR2 VAR3 VAR4 VAR5 VAR6 VAR7 VAR8 VAR9 VAR10

# ✅ Good: Only essential ARGs
ARG NODE_VERSION=18
ARG APP_VERSION=1.0.0
ARG ENVIRONMENT=production
```

### 10. ❌ Not Validating ARG Values

```dockerfile
# ❌ Bad: No validation
ARG ENVIRONMENT
RUN deploy-to-${ENVIRONMENT}  # Could be anything!

# ✅ Good: Validate input
ARG ENVIRONMENT=production
RUN if [ "$ENVIRONMENT" != "dev" ] && \
       [ "$ENVIRONMENT" != "staging" ] && \
       [ "$ENVIRONMENT" != "production" ]; then \
        echo "Invalid ENVIRONMENT" && exit 1; \
    fi
```

### 11. ❌ Hardcoding Values That Should Be ARGs

```dockerfile
# ❌ Bad: Hardcoded version
FROM node:18-alpine
COPY package.json ./
RUN npm install

# ✅ Good: Flexible with ARG
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine
COPY package.json ./
RUN npm install
```

### 12. ❌ Missing Documentation

```dockerfile
# ❌ Bad: No explanation
ARG X=123
ARG Y=456
ARG Z=789

# ✅ Good: Clear documentation
# Application version number
ARG APP_VERSION=1.0.0

# Node.js major version (18, 20, etc.)
ARG NODE_VERSION=18

# Build environment (development, staging, production)
ARG ENVIRONMENT=production
```

---

## Troubleshooting

### Issue 1: ARG Not Working After FROM

**Problem:**
```dockerfile
ARG VERSION=1.0.0
FROM node:18
RUN echo ${VERSION}  # Empty!
```

**Solution:**
```dockerfile
ARG VERSION=1.0.0
FROM node:18
ARG VERSION  # Redeclare after FROM
RUN echo ${VERSION}  # Works now
```

**Why:** ARGs before FROM have global scope for FROM instructions but must be redeclared in build stages.

---

### Issue 2: Build Cache Not Invalidating

**Problem:**
```dockerfile
ARG VERSION=1.0.0
FROM node:18
LABEL version="${VERSION}"

# Build with different VERSION but layer cached
# docker build --build-arg VERSION=2.0.0 -t app .
# Still shows version 1.0.0!
```

**Solution:**
```dockerfile
ARG VERSION=1.0.0
FROM node:18
# Add a cache-busting instruction
ARG VERSION
LABEL version="${VERSION}"
```

**Why:** The LABEL layer is cached. Redeclaring ARG creates a new instruction that invalidates cache.

---

### Issue 3: ARG Value Not Persisting to Runtime

**Problem:**
```dockerfile
ARG API_URL=https://api.example.com
FROM node:18
CMD curl ${API_URL}  # API_URL is empty!
```

**Solution:**
```dockerfile
ARG API_URL=https://api.example.com
FROM node:18
ENV API_URL=${API_URL}  # Convert to ENV
CMD curl ${API_URL}  # Works now
```

**Why:** ARG is build-time only. Use ENV for runtime variables.

---

### Issue 4: Secrets Visible in Image History

**Problem:**
```dockerfile
ARG SECRET_KEY=abc123
FROM alpine
RUN echo ${SECRET_KEY} > /tmp/key

# docker history shows SECRET_KEY!
```

**Solution:**
```dockerfile
# syntax=docker/dockerfile:1.4
FROM alpine
RUN --mount=type=secret,id=secret_key \
    cat /run/secrets/secret_key > /tmp/key

# Build: docker build --secret id=secret_key,src=key.txt -t app .
```

**Why:** ARG values are stored in image metadata. Use BuildKit secrets for sensitive data.

---

### Issue 5: Multi-Platform Build Fails

**Problem:**
```dockerfile
FROM golang:1.21
COPY . .
RUN go build -o server  # Fails on different architectures
```

**Solution:**
```dockerfile
ARG TARGETOS
ARG TARGETARCH

FROM golang:1.21
COPY . .
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o server
```

**Why:** Need to specify target platform for cross-compilation.

---

### Issue 6: Conditional Logic Not Working

**Problem:**
```dockerfile
ARG ENABLE_FEATURE=true
FROM alpine
RUN if [ ${ENABLE_FEATURE} = "true" ]; then \
        echo "enabled"; \
    fi
# Error: [: =: unexpected operator
```

**Solution:**
```dockerfile
ARG ENABLE_FEATURE=true
FROM alpine
RUN if [ "${ENABLE_FEATURE}" = "true" ]; then \
        echo "enabled"; \
    fi
# Use quotes around variable
```

**Why:** Shell requires quotes for string comparison.

---

### Issue 7: ARG Not Overriding at Build Time

**Problem:**
```bash
docker build --build-arg VERSION=2.0.0 -t app .
# Still using VERSION=1.0.0
```

**Solution:**
Check Dockerfile:
```dockerfile
# ❌ Wrong: ARG after it's used
FROM node:18
LABEL version="${VERSION}"  # VERSION not defined yet
ARG VERSION=1.0.0

# ✅ Correct: ARG before use
FROM node:18
ARG VERSION=1.0.0
LABEL version="${VERSION}"
```

---

### Issue 8: Variable Expansion Not Working

**Problem:**
```dockerfile
ARG BASE=node
ARG VERSION=18
FROM ${BASE}:${VERSION}  # Works

ARG IMAGE=${BASE}:${VERSION}  # IMAGE is empty!
FROM ${IMAGE}  # Fails
```

**Solution:**
```dockerfile
ARG BASE=node
ARG VERSION=18

# Use in FROM directly
FROM ${BASE}:${VERSION}

# Note: Complex expansion in ARG defaults doesn't always work
# Better to compute in RUN
RUN echo "${BASE}:${VERSION}" > /image-name.txt
```

---

### Issue 9: BuildKit Not Enabled

**Problem:**
```dockerfile
# syntax=docker/dockerfile:1.4
RUN --mount=type=secret,id=key ...
# Error: unknown flag: --mount
```

**Solution:**
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker build -t app .

# Or per-command
DOCKER_BUILDKIT=1 docker build -t app .
```

---

### Issue 10: Proxy Not Working

**Problem:**
```dockerfile
FROM ubuntu:22.04
RUN apt-get update  # Fails behind corporate proxy
```

**Solution:**
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

FROM ubuntu:22.04

# Set proxy
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV no_proxy=${NO_PROXY}

RUN apt-get update && apt-get install -y curl
```

```bash
# Build with proxy
docker build \
  --build-arg HTTP_PROXY=http://proxy:8080 \
  --build-arg HTTPS_PROXY=http://proxy:8080 \
  --build-arg NO_PROXY=localhost,127.0.0.1 \
  -t app .
```

---

### Debugging Techniques

#### 1. Inspect ARG Values

```dockerfile
ARG VERSION=1.0.0
ARG NODE_VERSION=18

FROM node:${NODE_VERSION}
ARG VERSION
ARG NODE_VERSION

# Debug: Print all ARG values
RUN echo "Version: ${VERSION}" && \
    echo "Node: ${NODE_VERSION}"
```

#### 2. Check Image History

```bash
# See ARG values used in build
docker history myimage --no-trunc

# See specific layer
docker history myimage --no-trunc | grep -i "arg"
```

#### 3. Inspect Image Metadata

```bash
# Check labels with ARG values
docker image inspect myimage | jq '.[0].Config.Labels'

# Check environment variables
docker image inspect myimage | jq '.[0].Config.Env'
```

#### 4. Verify Build Args Were Passed

```bash
# Build with verbose output
docker build --progress=plain --no-cache -t app .

# Check what ARGs were received
docker build --progress=plain --build-arg VERSION=1.2.3 -t app . 2>&1 | grep -i arg
```

#### 5. Test ARG Scope

```dockerfile
ARG GLOBAL=global

FROM alpine AS stage1
ARG GLOBAL
RUN echo "Stage1: ${GLOBAL}"

FROM alpine AS stage2
ARG GLOBAL
RUN echo "Stage2: ${GLOBAL}"

FROM alpine AS stage3
# Missing ARG declaration
RUN echo "Stage3: ${GLOBAL}"  # Empty - helps identify scope issues
```

---

## Decision Matrix

### When to Use ARG vs ENV vs BuildKit Secrets

| Use Case | ARG | ENV | BuildKit Secret |
|----------|-----|-----|-----------------|
| Base image version | ✅ | ❌ | ❌ |
| Dependency versions | ✅ | ❌ | ❌ |
| Build flags | ✅ | ❌ | ❌ |
| Application version | ✅ | ✅ | ❌ |
| Runtime port | ❌ | ✅ | ❌ |
| Database URL | ❌ | ✅ | ❌ |
| API keys | ❌ | ❌ | ✅ |
| Passwords | ❌ | ❌ | ✅ |
| Private keys | ❌ | ❌ | ✅ |
| Certificates | ❌ | ❌ | ✅ |
| Build metadata | ✅ | ✅ | ❌ |
| Feature flags (build) | ✅ | ❌ | ❌ |
| Feature flags (runtime) | ❌ | ✅ | ❌ |

### Decision Tree

```
Need configuration? 
    ├─ Used at runtime?
    │   ├─ Yes → Use ENV
    │   └─ No → Continue
    │
    ├─ Is it sensitive?
    │   ├─ Yes → Use BuildKit Secret
    │   └─ No → Continue
    │
    ├─ Used during build only?
    │   ├─ Yes → Use ARG
    │   └─ No → Reconsider requirement
    │
    └─ Need both build and runtime?
        └─ Use ARG + ENV (convert)
```

### Quick Reference

```dockerfile
# Build-time configuration (non-sensitive)
ARG NODE_VERSION=18
ARG BUILD_ENV=production

# Runtime configuration
ENV PORT=3000
ENV LOG_LEVEL=info

# Build-time → Runtime conversion
ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}

# Sensitive data (never in ARG or ENV)
RUN --mount=type=secret,id=api_key \
    export API_KEY=$(cat /run/secrets/api_key)
```

---

## Summary

### Key Takeaways

1. **ARG is for build-time variables only** - Not available at runtime
2. **Always provide default values** - Makes builds predictable
3. **Never use ARG for secrets** - They're stored in image history
4. **Redeclare ARG in each stage** - Required for multi-stage builds
5. **Use ENV for runtime variables** - Can convert ARG→ENV if needed
6. **Position ARGs carefully** - Affects build cache
7. **Document your ARGs** - Makes Dockerfiles maintainable
8. **Validate ARG values** - Prevent invalid configurations
9. **Use BuildKit secrets for sensitive data** - Secure alternative
10. **Test with different ARG values** - Ensure flexibility works

### Common Patterns

```dockerfile
# Pattern 1: Basic versioning
ARG VERSION=1.0.0
FROM node:${VERSION}

# Pattern 2: Environment builds
ARG ENV=production
RUN if [ "$ENV" = "production" ]; then npm run build:prod; fi

# Pattern 3: ARG to ENV
ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}

# Pattern 4: Multi-stage ARG
ARG VERSION=1.0.0
FROM node:18 AS builder
ARG VERSION  # Redeclare
LABEL version="${VERSION}"

# Pattern 5: Conditional features
ARG ENABLE_REDIS=false
RUN [ "$ENABLE_REDIS" = "true" ] && apk add redis || true
```

### Best Practices Checklist

- [ ] All ARGs have default values
- [ ] ARGs are documented at top of Dockerfile
- [ ] No secrets in ARG declarations
- [ ] ARGs redeclared in each stage where needed
- [ ] ARG position optimized for cache efficiency
- [ ] ARG values validated when critical
- [ ] Build tested with different ARG values
- [ ] Multi-platform builds use TARGETARCH/TARGETOS
- [ ] Sensitive data uses BuildKit secrets
- [ ] Runtime configuration uses ENV, not ARG

---

## Additional Resources

### Official Documentation
- [Dockerfile ARG Reference](https://docs.docker.com/engine/reference/builder/#arg)
- [Docker Build Arguments](https://docs.docker.com/build/building/variables/)
- [BuildKit Secrets](https://docs.docker.com/build/building/secrets/)

### Security
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Image Scanning Tools](https://docs.docker.com/engine/scan/)

### Tools
- `docker history` - View image layer history
- `docker inspect` - Inspect image metadata
- `trivy` - Vulnerability scanner
- `hadolint` - Dockerfile linter

---

**Last Updated:** 2024
**Version:** 1.0.0

---

*For more Docker guides, see the [complete Docker instructions series](./00-all-docker-file-instructions.MD)*
