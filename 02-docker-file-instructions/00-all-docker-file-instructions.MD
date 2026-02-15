# All Dockerfile Instructions - Complete Reference

> Comprehensive list of all Dockerfile instructions with brief descriptions. Each instruction has a detailed page in this folder.

## Table of Contents

1. [FROM](#from)
2. [RUN](#run)
3. [CMD](#cmd)
4. [LABEL](#label)
5. [EXPOSE](#expose)
6. [ENV](#env)
7. [ADD](#add)
8. [COPY](#copy)
9. [ENTRYPOINT](#entrypoint)
10. [VOLUME](#volume)
11. [USER](#user)
12. [WORKDIR](#workdir)
13. [ARG](#arg)
14. [ONBUILD](#onbuild)
15. [STOPSIGNAL](#stopsignal)
16. [HEALTHCHECK](#healthcheck)
17. [SHELL](#shell)
18. [MAINTAINER](#maintainer) (Deprecated)

---

## FROM

**Purpose:** Sets the base image for subsequent instructions.

**Brief:** Every Dockerfile must start with FROM (except ARG before FROM). It initializes a new build stage and sets the base image. Essential for multi-stage builds.

**Syntax:** 
```dockerfile
FROM <image>[:<tag>] [AS <name>]
FROM <image>[@<digest>] [AS <name>]
```

**Examples:**
```dockerfile
FROM ubuntu:22.04
FROM node:18-alpine AS builder
FROM scratch
FROM nginx@sha256:abc123...
```

**Used For:**
- Setting base image
- Multi-stage builds
- Defining build stages

📄 **Detailed Guide:** [01-FROM.MD](./01-FROM.MD)

---

## RUN

**Purpose:** Executes commands in a new layer on top of the current image and commits the results.

**Brief:** Used to install packages, run scripts, and perform build-time operations. Each RUN creates a new layer in the image.

**Syntax:** 
```dockerfile
RUN <command>                              # Shell form
RUN ["executable", "param1", "param2"]    # Exec form
```

**Examples:**
```dockerfile
RUN apt-get update && apt-get install -y nginx
RUN npm install
RUN pip install -r requirements.txt
RUN go build -o app
```

**Used For:**
- Installing packages
- Running build scripts
- Compiling code
- Setting permissions

📄 **Detailed Guide:** [02-RUN.MD](./02-RUN.MD)

---

## CMD

**Purpose:** Provides default command and/or parameters for an executing container.

**Brief:** Defines the default command to run when container starts. Can be overridden at runtime. Only the last CMD in a Dockerfile takes effect.

**Syntax:**
```dockerfile
CMD ["executable","param1","param2"]       # Exec form (preferred)
CMD command param1 param2                  # Shell form
CMD ["param1","param2"]                    # As default params to ENTRYPOINT
```

**Examples:**
```dockerfile
CMD ["nginx", "-g", "daemon off;"]
CMD ["node", "server.js"]
CMD ["python", "app.py"]
CMD npm start
```

**Used For:**
- Default application command
- Default arguments to ENTRYPOINT
- Container startup behavior

📄 **Detailed Guide:** [03-CMD.MD](./03-CMD.MD)

---

## LABEL

**Purpose:** Adds metadata to an image as key-value pairs.

**Brief:** Used for documentation, versioning, licensing, and image organization. Labels are inherited from base images.

**Syntax:** 
```dockerfile
LABEL <key>=<value> <key>=<value> ...
```

**Examples:**
```dockerfile
LABEL version="1.0" maintainer="devops@company.com"
LABEL org.opencontainers.image.version="1.2.3"
LABEL description="Production web server"
LABEL build.date="2024-02-14"
```

**Used For:**
- Version tracking
- Maintainer information
- License details
- Build metadata
- OCI annotations

📄 **Detailed Guide:** [04-LABEL.MD](./04-LABEL.MD)

---

## EXPOSE

**Purpose:** Informs Docker that the container listens on specified network ports at runtime.

**Brief:** Documents which ports are intended to be published. Does NOT actually publish the port - use -p flag with docker run.

**Syntax:** 
```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

**Examples:**
```dockerfile
EXPOSE 80
EXPOSE 80/tcp 443/tcp
EXPOSE 3000 3001 9229
EXPOSE 53/udp
```

**Used For:**
- Documenting exposed ports
- Inter-container communication
- Default port mapping with -P flag

📄 **Detailed Guide:** [05-EXPOSE.MD](./05-EXPOSE.MD)

---

## ENV

**Purpose:** Sets environment variables that persist in the image and running container.

**Brief:** Used to set configuration values available during build and at runtime. ENV values can be overridden at runtime.

**Syntax:** 
```dockerfile
ENV <key>=<value> ...
ENV <key> <value>
```

**Examples:**
```dockerfile
ENV NODE_ENV=production
ENV APP_HOME=/app PORT=3000
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/bin:${PATH}"
```

**Used For:**
- Application configuration
- Runtime environment setup
- PATH modification
- Default settings

📄 **Detailed Guide:** [06-ENV.MD](./06-ENV.MD)

---

## ADD

**Purpose:** Copies files, directories, or remote URLs from source to the image filesystem.

**Brief:** Similar to COPY but with extra features (tar extraction, URL downloads). Prefer COPY unless you need ADD's special features.

**Syntax:** 
```dockerfile
ADD [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

**Examples:**
```dockerfile
ADD app.tar.gz /app/
ADD https://example.com/file.tar.gz /tmp/
ADD --chown=node:node app.tar.gz /app/
```

**Used For:**
- Extracting tar archives
- Downloading from URLs (not recommended)
- Adding files with ownership

📄 **Detailed Guide:** [07-ADD.MD](./07-ADD.MD)

---

## COPY

**Purpose:** Copies files or directories from build context into the image.

**Brief:** Preferred over ADD for simple file copying. More transparent and predictable. Can copy from other build stages.

**Syntax:** 
```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
COPY --from=<stage> <src> <dest>
```

**Examples:**
```dockerfile
COPY package.json /app/
COPY --chown=node:node . /app
COPY --from=builder /app/dist /app/dist
COPY *.py /app/
```

**Used For:**
- Copying application code
- Copying configuration files
- Multi-stage build artifacts
- Dependency files

📄 **Detailed Guide:** [08-COPY.MD](./08-COPY.MD)

---

## ENTRYPOINT

**Purpose:** Configures a container to run as an executable.

**Brief:** Sets the main command that always runs. Unlike CMD, not easily overridden. Often used with CMD for default arguments.

**Syntax:**
```dockerfile
ENTRYPOINT ["executable", "param1", "param2"]  # Exec form (preferred)
ENTRYPOINT command param1 param2               # Shell form
```

**Examples:**
```dockerfile
ENTRYPOINT ["python", "app.py"]
ENTRYPOINT ["docker-entrypoint.sh"]
ENTRYPOINT ["/app/server"]
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Used For:**
- Container as executable
- Initialization scripts
- Fixed base command
- Combined with CMD for flexibility

📄 **Detailed Guide:** [09-ENTRYPOINT.MD](./09-ENTRYPOINT.MD)

---

## VOLUME

**Purpose:** Creates a mount point for externally mounted volumes or other containers.

**Brief:** Used for persistent data that should survive container restarts and removals. Data stored in volumes is not included in image layers.

**Syntax:** 
```dockerfile
VOLUME ["/data"]
VOLUME /data /var/log
```

**Examples:**
```dockerfile
VOLUME /var/lib/mysql
VOLUME ["/var/log", "/var/db"]
VOLUME /app/uploads
VOLUME /data
```

**Used For:**
- Database storage
- Log directories
- User uploads
- Persistent application data
- Shared data between containers

📄 **Detailed Guide:** [10-VOLUME.MD](./10-VOLUME.MD)

---

## USER

**Purpose:** Sets the user (and optionally group) for subsequent instructions and container runtime.

**Brief:** Critical for security - run containers as non-root user in production. Affects RUN, CMD, ENTRYPOINT instructions.

**Syntax:** 
```dockerfile
USER <user>[:<group>]
USER <UID>[:<GID>]
```

**Examples:**
```dockerfile
USER node
USER node:node
USER 1001:1001
USER appuser
```

**Used For:**
- Security (non-root execution)
- Permission management
- Least privilege principle
- Compliance requirements

📄 **Detailed Guide:** [11-USER.MD](./11-USER.MD)

---

## WORKDIR

**Purpose:** Sets the working directory for any subsequent RUN, CMD, ENTRYPOINT, COPY, and ADD instructions.

**Brief:** Changes the current directory. Creates it if it doesn't exist. Can be used multiple times in a Dockerfile.

**Syntax:** 
```dockerfile
WORKDIR /path/to/workdir
```

**Examples:**
```dockerfile
WORKDIR /app
WORKDIR /var/www/html
WORKDIR $APP_HOME
WORKDIR src
```

**Used For:**
- Setting application directory
- Organizing file structure
- Relative path operations
- Container working directory

📄 **Detailed Guide:** [12-WORKDIR.MD](./12-WORKDIR.MD)

---

## ARG

**Purpose:** Defines a build-time variable that users can pass at build-time with docker build --build-arg.

**Brief:** Only available during build, not in running container. Can have default values. Can be used before FROM for base image selection.

**Syntax:** 
```dockerfile
ARG <name>[=<default value>]
```

**Examples:**
```dockerfile
ARG VERSION=1.0
ARG NODE_VERSION=18
ARG BUILD_DATE
ARG ENVIRONMENT=production
```

**Used For:**
- Build-time configuration
- Version selection
- Environment-specific builds
- Build metadata
- Conditional builds

📄 **Detailed Guide:** [13-ARG.MD](./13-ARG.MD)

---

## ONBUILD

**Purpose:** Adds a trigger instruction to execute when the image is used as base for another build.

**Brief:** Deferred execution - runs when someone builds FROM this image. Useful for creating base images with standard build steps.

**Syntax:** 
```dockerfile
ONBUILD <INSTRUCTION>
```

**Examples:**
```dockerfile
ONBUILD COPY . /app
ONBUILD RUN npm install
ONBUILD ADD config.json /config/
ONBUILD WORKDIR /app
```

**Used For:**
- Standard base images
- Company-wide build patterns
- Automated dependency installation
- Template images

📄 **Detailed Guide:** [14-ONBUILD.MD](./14-ONBUILD.MD)

---

## STOPSIGNAL

**Purpose:** Sets the system call signal that will be sent to the container to exit.

**Brief:** Controls how container stops. Default is SIGTERM. Application must handle the specified signal for graceful shutdown.

**Syntax:** 
```dockerfile
STOPSIGNAL signal
```

**Examples:**
```dockerfile
STOPSIGNAL SIGTERM
STOPSIGNAL SIGQUIT
STOPSIGNAL SIGINT
STOPSIGNAL 15
```

**Used For:**
- Graceful shutdown
- Custom signal handling
- Application-specific stop behavior
- Legacy application compatibility

📄 **Detailed Guide:** [15-STOPSIGNAL.MD](./15-STOPSIGNAL.MD)

---

## HEALTHCHECK

**Purpose:** Tells Docker how to test if container is still working properly.

**Brief:** Enables automatic health monitoring and self-healing in orchestration systems. Can be disabled with HEALTHCHECK NONE.

**Syntax:** 
```dockerfile
HEALTHCHECK [OPTIONS] CMD command
HEALTHCHECK NONE
```

**Options:**
- `--interval=DURATION` (default: 30s)
- `--timeout=DURATION` (default: 30s)
- `--start-period=DURATION` (default: 0s)
- `--retries=N` (default: 3)

**Examples:**
```dockerfile
HEALTHCHECK --interval=30s CMD curl -f http://localhost/ || exit 1
HEALTHCHECK CMD wget --quiet --tries=1 --spider http://localhost:8080/health
HEALTHCHECK --interval=5m --timeout=3s CMD pg_isready
HEALTHCHECK NONE
```

**Used For:**
- Container health monitoring
- Automatic restarts
- Load balancer integration
- Service discovery
- Zero-downtime deployments

📄 **Detailed Guide:** [16-HEALTHCHECK.MD](./16-HEALTHCHECK.MD)

---

## SHELL

**Purpose:** Changes the default shell used for shell-form commands.

**Brief:** Allows using a different shell (bash, powershell, etc.) instead of default /bin/sh on Linux or cmd on Windows.

**Syntax:** 
```dockerfile
SHELL ["executable", "parameters"]
```

**Examples:**
```dockerfile
SHELL ["/bin/bash", "-c"]
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
SHELL ["powershell", "-command"]
SHELL ["cmd", "/S", "/C"]
```

**Used For:**
- Using bash instead of sh
- PowerShell on Windows
- Shell-specific features
- Strict error handling
- Custom shell environments

📄 **Detailed Guide:** [17-SHELL.MD](./17-SHELL.MD)

---

## MAINTAINER (Deprecated)

**Purpose:** Sets the Author field of the generated images.

**Brief:** **DEPRECATED** - Use LABEL instead with `LABEL maintainer="email@example.com"`

**Syntax:** 
```dockerfile
MAINTAINER <name> <email>
```

**Replacement:**
```dockerfile
# Old way (deprecated)
MAINTAINER John Doe <john@example.com>

# New way (recommended)
LABEL maintainer="john@example.com"
LABEL org.opencontainers.image.authors="john@example.com"
```

**Note:** Included for completeness, but should not be used in new Dockerfiles.

---

## Quick Comparison Table

| Instruction | Build Time | Runtime | Can Override | Primary Use Case |
|-------------|-----------|---------|--------------|------------------|
| **FROM** | ✅ | ❌ | ❌ | Set base image |
| **RUN** | ✅ | ❌ | ❌ | Install packages, build |
| **CMD** | ❌ | ✅ | ✅ | Default command |
| **ENTRYPOINT** | ❌ | ✅ | ⚠️ | Main executable |
| **COPY** | ✅ | ❌ | ❌ | Copy files |
| **ADD** | ✅ | ❌ | ❌ | Copy + extract/download |
| **ENV** | ✅ | ✅ | ✅ | Environment variables |
| **ARG** | ✅ | ❌ | ✅ | Build arguments |
| **WORKDIR** | ✅ | ✅ | ❌ | Set working directory |
| **USER** | ✅ | ✅ | ❌ | Set user context |
| **EXPOSE** | ✅ | ✅ | ❌ | Document ports |
| **VOLUME** | ✅ | ✅ | ❌ | Persistent storage |
| **LABEL** | ✅ | ✅ | ❌ | Metadata |
| **HEALTHCHECK** | ✅ | ✅ | ❌ | Health monitoring |
| **SHELL** | ✅ | ❌ | ❌ | Change default shell |
| **STOPSIGNAL** | ✅ | ✅ | ❌ | Stop signal |
| **ONBUILD** | ✅ | ❌ | ❌ | Child image triggers |

---

## Instruction Categories

### 🏗️ **Build Instructions** (Execute during build)
- **FROM** - Base image selection
- **RUN** - Execute build commands
- **COPY** - Copy files from context
- **ADD** - Copy with special features
- **WORKDIR** - Set build directory

### ⚙️ **Configuration Instructions** (Set container properties)
- **ENV** - Environment variables
- **ARG** - Build arguments
- **LABEL** - Image metadata
- **EXPOSE** - Port documentation
- **VOLUME** - Volume mount points
- **USER** - Execution user
- **WORKDIR** - Working directory

### 🚀 **Runtime Instructions** (Control container execution)
- **CMD** - Default command
- **ENTRYPOINT** - Main executable
- **HEALTHCHECK** - Health monitoring
- **STOPSIGNAL** - Stop signal

### 🔧 **Special Instructions** (Advanced features)
- **SHELL** - Change default shell
- **ONBUILD** - Deferred execution
- **MAINTAINER** - ⚠️ Deprecated

---

## Execution Order

```dockerfile
# 1. ARG can appear before FROM
ARG BASE_IMAGE=node:18

# 2. FROM must be first (or after ARG)
FROM ${BASE_IMAGE}

# 3. LABEL, ENV, ARG can be anywhere
LABEL version="1.0"
ENV NODE_ENV=production
ARG BUILD_DATE

# 4. RUN, COPY, ADD, WORKDIR, USER during build
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
USER node

# 5. EXPOSE, VOLUME declare intentions
EXPOSE 3000
VOLUME /data

# 6. HEALTHCHECK, STOPSIGNAL set runtime behavior
HEALTHCHECK CMD curl -f http://localhost:3000/health
STOPSIGNAL SIGTERM

# 7. CMD or ENTRYPOINT (one or both, last wins)
ENTRYPOINT ["node"]
CMD ["server.js"]
```

---

## Best Practices by Instruction

### FROM
- ✅ Use specific tags, not `latest`
- ✅ Pin by digest for reproducibility
- ✅ Use slim/alpine variants
- ✅ Use multi-stage builds

### RUN
- ✅ Chain commands with `&&`
- ✅ Clean up in same layer
- ✅ Use `--no-install-recommends` (apt)
- ✅ Sort multi-line alphabetically

### COPY vs ADD
- ✅ Prefer COPY for simple files
- ✅ Use ADD only for tar extraction
- ❌ Don't use ADD for URLs

### ENV vs ARG
- ✅ Use ARG for build-time only
- ✅ Use ENV for runtime config
- ❌ Never use for secrets

### USER
- ✅ Always use non-root in production
- ✅ Create dedicated user
- ✅ Use numeric UIDs for K8s

### CMD vs ENTRYPOINT
- ✅ Use ENTRYPOINT for main command
- ✅ Use CMD for default arguments
- ✅ Use exec form for both

### HEALTHCHECK
- ✅ Always include in production
- ✅ Test actual functionality
- ✅ Set appropriate timeouts

---

## Common Patterns

### 1. Multi-Stage Build Pattern
```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /build
COPY . .
RUN go build -o app

# Runtime stage
FROM alpine:3.18
COPY --from=builder /build/app /app
USER nobody
ENTRYPOINT ["/app"]
```

### 2. Security Pattern
```dockerfile
FROM node:18-alpine

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

WORKDIR /app

# Install dependencies as root
COPY package*.json ./
RUN npm ci --only=production

# Copy app and set ownership
COPY --chown=appuser:appuser . .

# Switch to non-root
USER appuser

# Health check
HEALTHCHECK --interval=30s CMD node healthcheck.js

# Run application
CMD ["node", "server.js"]
```

### 3. Build Arguments Pattern
```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

ARG BUILD_DATE
ARG VERSION
ARG GIT_COMMIT

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}"

ENV APP_VERSION=${VERSION}

# Build command:
# docker build \
#   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
#   --build-arg VERSION=1.2.3 \
#   --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
#   -t myapp:1.2.3 .
```

### 4. Configuration Pattern
```dockerfile
FROM python:3.11-slim

# Build-time configuration
ARG ENVIRONMENT=production

# Runtime configuration
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_ENV=${ENVIRONMENT}

WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Non-root user
RUN useradd -r -u 1001 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
    CMD python healthcheck.py

# Expose port
EXPOSE 8000

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

### 5. Volume Pattern
```dockerfile
FROM postgres:15-alpine

# Environment variables
ENV POSTGRES_DB=myapp \
    POSTGRES_USER=appuser \
    PGDATA=/var/lib/postgresql/data

# Persistent volumes
VOLUME /var/lib/postgresql/data
VOLUME /var/log/postgresql

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}

EXPOSE 5432
```

---

## Instruction Combinations

### ENTRYPOINT + CMD
```dockerfile
# Flexible command with default arguments
ENTRYPOINT ["python"]
CMD ["app.py"]

# Run: docker run myapp          → python app.py
# Run: docker run myapp test.py  → python test.py
```

### ENV + ARG
```dockerfile
# Convert build arg to runtime env
ARG VERSION=1.0
ENV APP_VERSION=${VERSION}

# Now VERSION available at build time
# APP_VERSION available at runtime
```

### USER + WORKDIR + COPY
```dockerfile
# Set directory and ownership
WORKDIR /app
COPY --chown=node:node . .
USER node

# Now runs as node user in /app directory
```

### EXPOSE + HEALTHCHECK
```dockerfile
# Document and monitor port
EXPOSE 8080
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1
```

---

## Production Checklist

### Must Have
- [ ] FROM with specific version (not latest)
- [ ] USER set to non-root
- [ ] HEALTHCHECK defined
- [ ] Multi-stage build (if applicable)
- [ ] LABEL with metadata

### Should Have
- [ ] WORKDIR set
- [ ] EXPOSE documented
- [ ] CMD or ENTRYPOINT in exec form
- [ ] Layer optimization
- [ ] .dockerignore file

### Best Practices
- [ ] Base image pinned by digest
- [ ] Dependencies pinned with lockfiles
- [ ] Secrets not in ENV or ARG
- [ ] Cleanup in same RUN layer
- [ ] VOLUME for persistent data

---

## Instruction Limitations

### Per Dockerfile
- **FROM**: Multiple allowed (multi-stage)
- **CMD**: Only last one used
- **ENTRYPOINT**: Only last one used
- **HEALTHCHECK**: Only last one used
- **SHELL**: Changes for subsequent instructions
- **USER**: Changes for subsequent instructions
- **WORKDIR**: Can be relative or absolute

### Special Cases
- **ARG** before FROM: Limited scope
- **ONBUILD**: Cannot trigger another ONBUILD
- **MAINTAINER**: Deprecated, don't use

---

## Complete Example

```dockerfile
# syntax=docker/dockerfile:1

###########################################
# Build Arguments
###########################################
ARG NODE_VERSION=18
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG GIT_COMMIT

###########################################
# Stage 1: Dependencies
###########################################
FROM node:${NODE_VERSION}-alpine AS dependencies

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

###########################################
# Stage 2: Builder
###########################################
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

###########################################
# Stage 3: Runtime
###########################################
FROM node:${NODE_VERSION}-alpine AS runtime

# Metadata
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.title="My App" \
      org.opencontainers.image.description="Production application"

# Environment variables
ENV NODE_ENV=production \
    PORT=3000

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy production dependencies
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Copy necessary files
COPY --chown=nodejs:nodejs package*.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Volume for logs
VOLUME /app/logs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

# Stop signal
STOPSIGNAL SIGTERM

# Start application
CMD ["node", "dist/server.js"]
```

---

## Resources

### Official Documentation
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [BuildKit](https://docs.docker.com/build/buildkit/)

### Industry Standards
- [OCI Image Spec](https://github.com/opencontainers/image-spec)
- [OCI Distribution Spec](https://github.com/opencontainers/distribution-spec)
- [12-Factor App](https://12factor.net/)

### Tools
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile linter
- [Dive](https://github.com/wagoodman/dive) - Image layer analyzer
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner

---

## Summary

### Core Instructions (Must Know)
1. **FROM** - Base image
2. **RUN** - Build commands
3. **COPY** - Copy files
4. **USER** - Security
5. **WORKDIR** - Directory
6. **CMD/ENTRYPOINT** - Runtime command

### Configuration Instructions
7. **ENV** - Environment variables
8. **ARG** - Build arguments
9. **EXPOSE** - Port documentation
10. **VOLUME** - Persistent data

### Advanced Instructions
11. **LABEL** - Metadata
12. **HEALTHCHECK** - Monitoring
13. **SHELL** - Custom shell
14. **STOPSIGNAL** - Stop behavior
15. **ONBUILD** - Triggers
16. **ADD** - Special copy

### Remember
- ✅ Start with FROM
- ✅ End with CMD or ENTRYPOINT
- ✅ Use USER for security
- ✅ Include HEALTHCHECK
- ✅ Add LABEL metadata
- ✅ Optimize layers
- ✅ Use multi-stage builds

---

**Last Updated:** February 2026  
**Docker Version:** 24.x and above  
**Completeness:** All 17 active instructions + 1 deprecated

---

*This document covers ALL Dockerfile instructions used in the industry. Each instruction has a dedicated detailed guide in this folder.*
