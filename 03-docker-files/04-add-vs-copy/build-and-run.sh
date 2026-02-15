#!/bin/bash

# DevOps Navigator - COPY Instruction Demo
# Build and Run Script with 6 Interactive Pages

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="devops-navigator"
IMAGE_TAG="v2"
CONTAINER_NAME="devops-nav"
HOST_PORT="8080"
CONTAINER_PORT="80"

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  DevOps Navigator - COPY Demo${NC}"
echo -e "${PURPLE}  Interactive Learning Platform${NC}"
echo -e "${PURPLE}========================================${NC}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    echo -e "${YELLOW}Install Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed${NC}"
docker --version
echo ""

# Check for app-files directory
if [ ! -d "app-files" ]; then
    echo -e "${RED}❌ app-files directory not found!${NC}"
    echo -e "${YELLOW}Make sure you're in: 04-add-vs-copy/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ app-files directory found${NC}"
echo -e "${BLUE}   Files: $(ls -1 app-files/*.html | wc -l) HTML pages${NC}"
echo ""

# Navigate to Dockerfiles directory
if [ -d "Dockerfiles" ]; then
    cd Dockerfiles
    echo -e "${GREEN}✅ Changed to Dockerfiles directory${NC}"
    echo -e "${BLUE}   Current: $(pwd)${NC}"
else
    echo -e "${YELLOW}⚠️  Already in Dockerfiles directory${NC}"
fi
echo ""

# Stop and remove existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}🛑 Stopping existing container: ${CONTAINER_NAME}${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Removing existing container: ${CONTAINER_NAME}${NC}"
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    echo ""
fi

# Build the image
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔨 Building Docker Image${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "${BLUE}   Instruction: COPY (not ADD)${NC}"
echo ""

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Image built successfully!${NC}"
    echo ""
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# Display image information
echo -e "${BLUE}📊 Image Information:${NC}"
docker images ${IMAGE_NAME}:${IMAGE_TAG} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""

# Display key labels
echo -e "${BLUE}🏷️  Key Labels:${NC}"
echo -e "${GREEN}   Instruction Used:${NC} $(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null | jq -r '.[0].Config.Labels["demo.instruction"]' || echo 'COPY')"
echo -e "${GREEN}   Version:${NC} $(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null | jq -r '.[0].Config.Labels["org.opencontainers.image.version"]' || echo '2.0.0')"
echo -e "${GREEN}   Title:${NC} $(docker inspect ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null | jq -r '.[0].Config.Labels["org.opencontainers.image.title"]' || echo 'DevOps Navigator')"
echo ""

# Run the container
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Starting Container${NC}"
echo -e "${BLUE}========================================${NC}"

docker run -d \
    -p ${HOST_PORT}:${CONTAINER_PORT} \
    --name ${CONTAINER_NAME} \
    --restart unless-stopped \
    ${IMAGE_NAME}:${IMAGE_TAG}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container started successfully!${NC}"
    echo ""
else
    echo -e "${RED}❌ Failed to start container!${NC}"
    exit 1
fi

# Wait for container to be ready
echo -e "${BLUE}⏳ Waiting for container to be ready...${NC}"
sleep 3
echo ""

# Verify container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ Container is running!${NC}"
    echo ""
    
    # Display container details
    echo -e "${BLUE}📦 Container Details:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Test endpoint
    echo -e "${BLUE}🔍 Testing HTTP endpoint...${NC}"
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HOST_PORT} | grep -q "200"; then
        echo -e "${GREEN}✅ HTTP endpoint is responding!${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP endpoint test failed${NC}"
    fi
    echo ""
    
    # Verify all files were copied
    echo -e "${BLUE}📁 Verifying COPY instruction worked:${NC}"
    echo ""
    echo -e "${GREEN}   Main file:${NC}"
    docker exec ${CONTAINER_NAME} ls -lh /usr/share/nginx/html/index.html 2>/dev/null || echo "   ⚠️ Not found"
    echo ""
    echo -e "${GREEN}   Linked pages (6 files):${NC}"
    FILE_COUNT=$(docker exec ${CONTAINER_NAME} ls /usr/share/nginx/html/app-files/*.html 2>/dev/null | wc -l)
    echo -e "   Found: ${FILE_COUNT} HTML files"
    docker exec ${CONTAINER_NAME} ls -1 /usr/share/nginx/html/app-files/ 2>/dev/null | sed 's/^/   - /'
    echo ""
    
    # Success message
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  🎉 SUCCESS! All Systems Ready!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${PURPLE}🌐 Access your application at:${NC}"
    echo -e "   ${GREEN}http://localhost:${HOST_PORT}${NC}"
    echo ""
    echo -e "${PURPLE}📚 Interactive Pages Available:${NC}"
    echo -e "   🐳 Docker Build     → http://localhost:${HOST_PORT}/app-files/docker-build.html"
    echo -e "   ▶️ Docker Run       → http://localhost:${HOST_PORT}/app-files/docker-run.html"
    echo -e "   🏷️ Docker Tag       → http://localhost:${HOST_PORT}/app-files/docker-tag.html"
    echo -e "   📤 Docker Push      → http://localhost:${HOST_PORT}/app-files/docker-push.html"
    echo -e "   🏷️ Docker Labels    → http://localhost:${HOST_PORT}/app-files/docker-labels.html"
    echo -e "   📋 COPY vs ADD     → http://localhost:${HOST_PORT}/app-files/copy-vs-add.html ${GREEN}⭐ NEW!${NC}"
    echo ""
    echo -e "${PURPLE}📝 Useful Commands:${NC}"
    echo -e "   View logs:        ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
    echo -e "   Follow logs:      ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "   Stop container:   ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "   Start container:  ${YELLOW}docker start ${CONTAINER_NAME}${NC}"
    echo -e "   Remove container: ${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
    echo -e "   Enter container:  ${YELLOW}docker exec -it ${CONTAINER_NAME} sh${NC}"
    echo -e "   View labels:      ${YELLOW}docker inspect ${CONTAINER_NAME} | jq '.[0].Config.Labels'${NC}"
    echo ""
    echo -e "${PURPLE}🎓 Learning Point:${NC}"
    echo -e "   This demo uses ${GREEN}COPY${NC} instruction (not ADD)"
    echo -e "   All 7 HTML files copied using COPY!"
    echo -e "   COPY is the recommended industry standard! ✅"
    echo ""
    
else
    echo -e "${RED}❌ Container failed to start!${NC}"
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  🎊 Ready to Learn Docker!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📖 Start by visiting:${NC} ${GREEN}http://localhost:${HOST_PORT}${NC}"
echo -e "${BLUE}🆕 Don't miss the new:${NC} ${GREEN}COPY vs ADD${NC} ${BLUE}page!${NC}"
echo ""
