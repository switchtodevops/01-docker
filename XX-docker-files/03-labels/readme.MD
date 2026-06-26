# DevOps Navigator - Docker Labels Guide

> Complete guide to using Docker LABEL instruction with production-ready examples and OCI standards

## 📋 Table of Contents

1. [Overview](#overview)
2. [What are Docker Labels?](#what-are-docker-labels)
3. [Labels in This Image](#labels-in-this-image)
4. [How to Read Labels](#how-to-read-labels)
5. [Production Usage](#production-usage)
6. [Filtering and Querying](#filtering-and-querying)
7. [CI/CD Integration](#cicd-integration)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Real-World Examples](#real-world-examples)

---

## Overview

This Docker image demonstrates the use of **OCI-compliant labels** for metadata management, automation, and production deployments.

**Image Details:**
- **Name:** `devops-navigator`
- **Version:** `v2`
- **Base:** `nginx:1.29.5-alpine-slim`
- **Theme:** Light Green
- **Labels:** OCI Standard compliant

---

## What are Docker Labels?

Docker labels are **key-value metadata** attached to Docker images and containers. They provide:

### Benefits

| Benefit | Description |
|---------|-------------|
| 📊 **Documentation** | Self-documenting images with version, author, description |
| 🔍 **Discovery** | Easy filtering and searching in registries |
| 🤖 **Automation** | CI/CD pipelines can read labels for decisions |
| 📈 **Monitoring** | Observability tools use labels for tracking |
| ✅ **Compliance** | Track licenses, security scans, approvals |
| 🏷️ **Organization** | Group images by team, project, environment |

### Industry Standard - OCI Labels

This image follows the [OCI Image Specification](https://github.com/opencontainers/image-spec/blob/main/annotations.md) using the `org.opencontainers.image.*` namespace.

---

## Labels in This Image

### View All Labels

```bash
docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'
```

### Expected Output

```json
{
  "org.opencontainers.image.version": "1.29.5",
  "org.opencontainers.image.authors": "DevOps Navigator <switchtodevops@gmail.com>",
  "org.opencontainers.image.description": "Demo Web Server",
  "org.opencontainers.image.build-date": "2026-02-15",
  "org.opencontainers.image.source": "https://github.com/DevOps-Navigator/nginx-image",
  "org.opencontainers.image.documentation": "https://github.com/DevOps-Navigator/nginx-image/blob/main/README.md",
  "org.opencontainers.image.vendor": "DevOps Navigator",
  "org.opencontainers.image.license": "MIT",
  "org.opencontainers.image.copyright": "Copyright 2026 DevOps Navigator",
  "org.opencontainers.image.url": "https://github.com/devops-team/nginx-image",
  "org.opencontainers.image.title": "DevOps Navigator"
}
```

### Label Breakdown

| Label | Value | Purpose |
|-------|-------|---------|
| `version` | `1.29.5` | Nginx version running in container |
| `authors` | `DevOps Navigator <email>` | Maintainer contact information |
| `description` | `Demo Web Server` | Brief image description |
| `build-date` | `2026-02-15` | When image was built |
| `source` | GitHub URL | Source code repository |
| `documentation` | GitHub README | Documentation link |
| `vendor` | `DevOps Navigator` | Organization/company name |
| `license` | `MIT` | Software license |
| `title` | `DevOps Navigator` | Human-readable image name |

---

## How to Read Labels

### Method 1: Using Docker Inspect (Formatted)

```bash
# Pretty print all labels
docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'
```

### Method 2: Get Specific Label

```bash
# Get version
docker inspect devops-navigator:v2 | jq -r '.[0].Config.Labels["org.opencontainers.image.version"]'

# Output: 1.29.5

# Get authors
docker inspect devops-navigator:v2 | jq -r '.[0].Config.Labels["org.opencontainers.image.authors"]'

# Output: DevOps Navigator <switchtodevops@gmail.com>
```

### Method 3: List All Labels (Key=Value Format)

```bash
docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels | to_entries[] | "\(.key)=\(.value)"'
```

**Output:**
```
org.opencontainers.image.version=1.29.5
org.opencontainers.image.authors=DevOps Navigator <switchtodevops@gmail.com>
org.opencontainers.image.description=Demo Web Server
org.opencontainers.image.build-date=2026-02-15
...
```

### Method 4: Using Docker Inspect with Format

```bash
# Without jq (built-in Docker formatting)
docker inspect --format='{{json .Config.Labels}}' devops-navigator:v2 | jq

# Specific label without jq
docker inspect --format='{{index .Config.Labels "org.opencontainers.image.version"}}' devops-navigator:v2
```

### Method 5: From Running Container

```bash
# Get container ID
docker ps --filter "ancestor=devops-navigator:v2" --format "{{.ID}}"

# Inspect container labels
docker inspect <container_id> | jq '.[0].Config.Labels'

# Or by container name
docker inspect devops-nav | jq '.[0].Config.Labels'
```

### Method 6: Create Label Report

```bash
# Save labels to file
docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels | to_entries[] | "\(.key)=\(.value)"' > labels.txt

# View the file
cat labels.txt
```

---

## Production Usage

### Scenario 1: Version Tracking

**Use Case:** Track which version is deployed in production

```bash
# Check deployed version
DEPLOYED_VERSION=$(docker inspect devops-nav | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

echo "Currently deployed version: $DEPLOYED_VERSION"

# Compare with new version
NEW_VERSION=$(docker inspect devops-navigator:v3 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

echo "New version: $NEW_VERSION"

# Decide if upgrade needed
if [ "$DEPLOYED_VERSION" != "$NEW_VERSION" ]; then
    echo "⚠️  Version mismatch - upgrade recommended"
fi
```

### Scenario 2: Automated Deployment Script

```bash
#!/bin/bash
# deploy.sh - Production deployment script

IMAGE_NAME="devops-navigator"
IMAGE_TAG="v2"

# Get image metadata from labels
VERSION=$(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

BUILD_DATE=$(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.build-date"]')

VENDOR=$(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.vendor"]')

# Log deployment
echo "=========================================="
echo "Deploying Image"
echo "=========================================="
echo "Image:       ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Version:     ${VERSION}"
echo "Build Date:  ${BUILD_DATE}"
echo "Vendor:      ${VENDOR}"
echo "=========================================="

# Deploy with labels for tracking
docker run -d \
  -p 8080:80 \
  --name ${IMAGE_NAME}-prod \
  --label deployment.environment="production" \
  --label deployment.date="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --label deployment.by="${USER}" \
  ${IMAGE_NAME}:${IMAGE_TAG}

echo "✅ Deployment complete!"
```

### Scenario 3: Health Check with Labels

```bash
#!/bin/bash
# healthcheck.sh - Verify running containers match expected versions

EXPECTED_VERSION="1.29.5"

# Get all running containers from this image
CONTAINERS=$(docker ps --filter "ancestor=devops-navigator:v2" --format "{{.Names}}")

for CONTAINER in $CONTAINERS; do
    VERSION=$(docker inspect $CONTAINER | \
      jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')
    
    if [ "$VERSION" != "$EXPECTED_VERSION" ]; then
        echo "⚠️  WARNING: $CONTAINER running version $VERSION (expected $EXPECTED_VERSION)"
    else
        echo "✅ $CONTAINER: version $VERSION (OK)"
    fi
done
```

### Scenario 4: Image Registry Organization

```bash
# Tag image for different environments using labels
SOURCE_IMAGE="devops-navigator:v2"

# Get version from labels
VERSION=$(docker inspect $SOURCE_IMAGE | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

# Tag for different registries/environments
docker tag $SOURCE_IMAGE registry.company.com/prod/devops-navigator:${VERSION}
docker tag $SOURCE_IMAGE registry.company.com/prod/devops-navigator:latest

# Push to registry
docker push registry.company.com/prod/devops-navigator:${VERSION}
docker push registry.company.com/prod/devops-navigator:latest

echo "✅ Pushed version ${VERSION} to production registry"
```

### Scenario 5: Audit and Compliance

```bash
#!/bin/bash
# audit.sh - Generate compliance report from labels

echo "=== Docker Image Audit Report ==="
echo "Generated: $(date)"
echo ""

# Check license compliance
LICENSE=$(docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.license"]')

echo "License: $LICENSE"

# Check vendor
VENDOR=$(docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.vendor"]')

echo "Vendor: $VENDOR"

# Check source code availability
SOURCE=$(docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.source"]')

echo "Source Code: $SOURCE"

# Check documentation
DOCS=$(docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.documentation"]')

echo "Documentation: $DOCS"

# Verify copyright
COPYRIGHT=$(docker inspect devops-navigator:v2 | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.copyright"]')

echo "Copyright: $COPYRIGHT"

echo ""
echo "✅ Audit complete - all metadata present"
```

---

## Filtering and Querying

### Filter Images by Label

```bash
# List all images with specific label
docker images --filter "label=org.opencontainers.image.vendor=DevOps Navigator"

# Filter by label key (any value)
docker images --filter "label=org.opencontainers.image.version"

# Multiple filters
docker images \
  --filter "label=org.opencontainers.image.vendor=DevOps Navigator" \
  --filter "label=org.opencontainers.image.version=1.29.5"
```

### Filter Containers by Label

```bash
# List running containers with label
docker ps --filter "label=org.opencontainers.image.vendor=DevOps Navigator"

# List all containers (including stopped)
docker ps -a --filter "label=org.opencontainers.image.version=1.29.5"

# Format output
docker ps --filter "label=org.opencontainers.image.vendor" \
  --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

### Advanced Queries

```bash
# Find images with specific author
docker images --format "{{.Repository}}:{{.Tag}}" | while read IMAGE; do
  AUTHOR=$(docker inspect $IMAGE 2>/dev/null | \
    jq -r '.[0].Config.Labels["org.opencontainers.image.authors"]' 2>/dev/null)
  
  if [[ $AUTHOR == *"DevOps Navigator"* ]]; then
    echo "$IMAGE - $AUTHOR"
  fi
done

# Generate inventory report
echo "=== Docker Image Inventory ==="
docker images --format "{{.Repository}}:{{.Tag}}" | while read IMAGE; do
  VERSION=$(docker inspect $IMAGE 2>/dev/null | \
    jq -r '.[0].Config.Labels["org.opencontainers.image.version"]' 2>/dev/null)
  VENDOR=$(docker inspect $IMAGE 2>/dev/null | \
    jq -r '.[0].Config.Labels["org.opencontainers.image.vendor"]' 2>/dev/null)
  
  if [ "$VERSION" != "null" ]; then
    echo "$IMAGE | Version: $VERSION | Vendor: $VENDOR"
  fi
done
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: devopsnavigator/devops-navigator
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
          labels: |
            org.opencontainers.image.title=DevOps Navigator
            org.opencontainers.image.description=Production web server
            org.opencontainers.image.vendor=DevOps Navigator

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Verify labels
        run: |
          docker pull devopsnavigator/devops-navigator:latest
          docker inspect devopsnavigator/devops-navigator:latest | \
            jq '.[0].Config.Labels'
```

### GitLab CI Example

```yaml
build-image:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - |
      docker build \
        --label "org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --label "org.opencontainers.image.version=$CI_COMMIT_TAG" \
        --label "org.opencontainers.image.revision=$CI_COMMIT_SHA" \
        --label "org.opencontainers.image.source=$CI_PROJECT_URL" \
        -t $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG \
        -t $CI_REGISTRY_IMAGE:latest \
        .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
    - docker push $CI_REGISTRY_IMAGE:latest
    - docker inspect $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG | jq '.[0].Config.Labels'
  only:
    - tags
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'devops-navigator'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        REGISTRY = 'registry.company.com'
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    def buildDate = sh(
                        script: "date -u +\"%Y-%m-%dT%H:%M:%SZ\"",
                        returnStdout: true
                    ).trim()
                    
                    def gitCommit = sh(
                        script: "git rev-parse HEAD",
                        returnStdout: true
                    ).trim()
                    
                    sh """
                        docker build \
                            --label "org.opencontainers.image.created=${buildDate}" \
                            --label "org.opencontainers.image.version=${IMAGE_TAG}" \
                            --label "org.opencontainers.image.revision=${gitCommit}" \
                            --label "build.jenkins.number=${BUILD_NUMBER}" \
                            --label "build.jenkins.url=${BUILD_URL}" \
                            -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                            .
                    """
                }
            }
        }
        
        stage('Verify Labels') {
            steps {
                sh """
                    echo "=== Image Labels ==="
                    docker inspect ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} | \
                        jq '.[0].Config.Labels'
                """
            }
        }
        
        stage('Push') {
            steps {
                sh """
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
```

---

## Best Practices

### 1. Always Use OCI Standard Labels

```dockerfile
# ✅ Good - OCI compliant
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="team@company.com"

# ❌ Bad - Non-standard
LABEL version="1.0.0"
LABEL maintainer="team@company.com"
```

### 2. Include Build Metadata

```dockerfile
ARG BUILD_DATE
ARG GIT_COMMIT
ARG VERSION

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.version="${VERSION}"
```

### 3. Document Everything

```dockerfile
LABEL org.opencontainers.image.title="My Application" \
      org.opencontainers.image.description="Complete description of what this does" \
      org.opencontainers.image.documentation="https://docs.company.com/myapp" \
      org.opencontainers.image.source="https://github.com/company/myapp"
```

### 4. Use Labels for Automation

```bash
# Deployment script reads labels
VERSION=$(docker inspect myapp:latest | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

if [ "$VERSION" == "null" ]; then
    echo "❌ ERROR: No version label found!"
    exit 1
fi

echo "Deploying version: $VERSION"
```

### 5. Query Before Deploy

```bash
# Verify labels exist before deploying
REQUIRED_LABELS=(
    "org.opencontainers.image.version"
    "org.opencontainers.image.authors"
    "org.opencontainers.image.source"
)

IMAGE="devops-navigator:v2"

for LABEL in "${REQUIRED_LABELS[@]}"; do
    VALUE=$(docker inspect $IMAGE | jq -r ".[0].Config.Labels[\"$LABEL\"]")
    if [ "$VALUE" == "null" ] || [ -z "$VALUE" ]; then
        echo "❌ Missing required label: $LABEL"
        exit 1
    fi
    echo "✅ $LABEL: $VALUE"
done

echo "✅ All required labels present"
```

---

## Troubleshooting

### Issue 1: Labels Not Showing

**Problem:**
```bash
docker inspect myimage:tag | jq '.[0].Config.Labels'
# Returns: null
```

**Solution:**
```bash
# Check if image exists
docker images | grep myimage

# Verify correct tag
docker images myimage

# Try without jq
docker inspect myimage:tag --format='{{.Config.Labels}}'
```

### Issue 2: jq Not Installed

**Problem:** `jq: command not found`

**Solution:**
```bash
# Install jq
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# macOS
brew install jq

# Or use docker inspect format
docker inspect --format='{{json .Config.Labels}}' myimage:tag
```

### Issue 3: Label Value Shows as "null"

**Problem:**
```bash
docker inspect myimage | jq -r '.[0].Config.Labels["mylabel"]'
# Returns: null
```

**Solution:**
```bash
# Check exact label key
docker inspect myimage | jq '.[0].Config.Labels | keys'

# Case sensitive - use exact key
docker inspect myimage | jq -r '.[0].Config.Labels["correct.key.name"]'
```

### Issue 4: Can't Filter by Label

**Problem:** `docker images --filter "label=version=1.0"` returns nothing

**Solution:**
```bash
# Check exact label format in image
docker inspect myimage:tag | jq '.[0].Config.Labels | to_entries[]'

# Use full OCI label name
docker images --filter "label=org.opencontainers.image.version=1.0"

# Or filter by key only
docker images --filter "label=org.opencontainers.image.version"
```

---

## Real-World Examples

### Example 1: Production Deployment with Label Verification

```bash
#!/bin/bash
# production-deploy.sh

set -e

IMAGE="devops-navigator"
TAG="v2"
FULL_IMAGE="${IMAGE}:${TAG}"

echo "=== Production Deployment ==="
echo ""

# 1. Pull latest image
echo "📥 Pulling image..."
docker pull ${FULL_IMAGE}

# 2. Verify labels
echo "🔍 Verifying labels..."
VERSION=$(docker inspect ${FULL_IMAGE} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

VENDOR=$(docker inspect ${FULL_IMAGE} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.vendor"]')

LICENSE=$(docker inspect ${FULL_IMAGE} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.license"]')

if [ "$VERSION" == "null" ]; then
    echo "❌ ERROR: Version label missing!"
    exit 1
fi

echo "✅ Version: $VERSION"
echo "✅ Vendor: $VENDOR"
echo "✅ License: $LICENSE"

# 3. Stop old container
echo "🛑 Stopping old container..."
docker stop ${IMAGE}-prod 2>/dev/null || true
docker rm ${IMAGE}-prod 2>/dev/null || true

# 4. Deploy new container
echo "🚀 Deploying new container..."
docker run -d \
    --name ${IMAGE}-prod \
    -p 80:80 \
    --restart unless-stopped \
    --label deployment.environment="production" \
    --label deployment.version="${VERSION}" \
    --label deployment.date="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    ${FULL_IMAGE}

# 5. Verify deployment
echo "✅ Verifying deployment..."
sleep 3

if docker ps | grep -q ${IMAGE}-prod; then
    echo "✅ Container running successfully!"
    echo ""
    echo "🎉 Deployment complete!"
    echo "📊 Version: $VERSION"
    echo "🌐 URL: http://localhost"
else
    echo "❌ Container failed to start!"
    docker logs ${IMAGE}-prod
    exit 1
fi
```

### Example 2: Multi-Environment Manager

```bash
#!/bin/bash
# env-manager.sh

function deploy_to_environment() {
    local ENV=$1
    local IMAGE=$2
    local TAG=$3
    
    echo "=== Deploying to ${ENV} ==="
    
    # Get image metadata
    VERSION=$(docker inspect ${IMAGE}:${TAG} | \
      jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')
    
    # Set environment-specific settings
    case $ENV in
        dev)
            PORT=8080
            REPLICAS=1
            ;;
        staging)
            PORT=8081
            REPLICAS=2
            ;;
        production)
            PORT=80
            REPLICAS=3
            ;;
        *)
            echo "❌ Unknown environment: $ENV"
            exit 1
            ;;
    esac
    
    # Deploy
    for i in $(seq 1 $REPLICAS); do
        docker run -d \
            --name ${IMAGE}-${ENV}-${i} \
            -p $((PORT + i - 1)):80 \
            --label deployment.environment="${ENV}" \
            --label deployment.version="${VERSION}" \
            --label deployment.replica="${i}" \
            ${IMAGE}:${TAG}
    done
    
    echo "✅ Deployed ${REPLICAS} replicas to ${ENV}"
    echo "📊 Version: ${VERSION}"
}

# Usage
deploy_to_environment "production" "devops-navigator" "v2"
```

### Example 3: Automated Rollback

```bash
#!/bin/bash
# rollback.sh

CURRENT_IMAGE="devops-navigator:v2"
PREVIOUS_IMAGE="devops-navigator:v1"

# Get versions
CURRENT_VERSION=$(docker inspect ${CURRENT_IMAGE} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

PREVIOUS_VERSION=$(docker inspect ${PREVIOUS_IMAGE} | \
  jq -r '.[0].Config.Labels["org.opencontainers.image.version"]')

echo "⚠️  Rolling back from v${CURRENT_VERSION} to v${PREVIOUS_VERSION}"

# Stop current
docker stop devops-nav-prod

# Start previous version
docker run -d \
    --name devops-nav-prod \
    -p 80:80 \
    --restart unless-stopped \
    --label deployment.environment="production" \
    --label deployment.rollback="true" \
    --label deployment.previous-version="${CURRENT_VERSION}" \
    ${PREVIOUS_IMAGE}

echo "✅ Rollback complete!"
```

---

## Quick Reference

### Essential Commands

```bash
# View all labels
docker inspect IMAGE | jq '.[0].Config.Labels'

# Get specific label
docker inspect IMAGE | jq -r '.[0].Config.Labels["KEY"]'

# Filter images by label
docker images --filter "label=KEY=VALUE"

# Filter containers by label
docker ps --filter "label=KEY=VALUE"

# List label keys
docker inspect IMAGE | jq '.[0].Config.Labels | keys'

# Export labels to file
docker inspect IMAGE | jq '.[0].Config.Labels' > labels.json
```

### Common Label Keys

```bash
org.opencontainers.image.version      # Version number
org.opencontainers.image.authors      # Maintainer info
org.opencontainers.image.description  # Image description
org.opencontainers.image.source       # Source code URL
org.opencontainers.image.vendor       # Company/organization
org.opencontainers.image.licenses     # License type
```

---

## Additional Resources

- **OCI Image Spec:** https://github.com/opencontainers/image-spec/blob/main/annotations.md
- **Docker Labels Documentation:** https://docs.docker.com/config/labels-custom-metadata/
- **Label Best Practices:** https://docs.docker.com/develop/dev-best-practices/
- **Complete LABEL Guide:** [../../02-docker-file-instructions/01-LABELS.MD](../../02-docker-file-instructions/01-LABELS.MD)

---

## Summary

### Key Takeaways

1. ✅ **Use OCI Standard Labels** - Follow `org.opencontainers.image.*` convention
2. ✅ **Read Labels with jq** - `docker inspect IMAGE | jq '.[0].Config.Labels'`
3. ✅ **Filter by Labels** - `docker images --filter "label=KEY=VALUE"`
4. ✅ **Automate with Labels** - Use in scripts for version tracking
5. ✅ **Document Everything** - Labels serve as living documentation
6. ✅ **Verify Before Deploy** - Check required labels exist
7. ✅ **Track in Production** - Use labels for monitoring and audit

### Next Steps

1. 🔨 Build the image: `docker build -t devops-navigator:v2 .`
2. 🔍 Inspect labels: `docker inspect devops-navigator:v2 | jq '.[0].Config.Labels'`
3. 🚀 Deploy to production with label verification
4. 📊 Set up monitoring using label metadata
5. 🔄 Integrate labels into your CI/CD pipeline

---

**Version:** v2  
**Last Updated:** February 2026  
**Maintained By:** DevOps Navigator Team  
**License:** MIT

---

*For detailed LABEL instruction documentation, see [01-LABELS.MD](../../02-docker-file-instructions/01-LABELS.MD)*
