#!/bin/bash

# DevOps Navigator - COPY Instruction Demo
# Build and Run Script

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="devops-navigator"
IMAGE_TAG="v2"
CONTAINER_NAME="devops-nav"
HOST_PORT="8080"
CONTAINER_PORT="80"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DevOps Navigator - COPY Demo${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed${NC}"
echo ""

# Navigate to Dockerfiles directory
cd "$(dirname "$0")/Dockerfiles"
echo -e "${BLUE}📂 Working directory: $(pwd)${NC}"
echo ""

# Stop and remove existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}🛑 Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Removing existing container...${NC}"
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    echo ""
fi

# Build the image
echo -e "${BLUE}🔨 Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "${BLUE}   Using COPY instruction to copy HTML files${NC}"
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
docker images ${IMAGE_NAME}:${IMAGE_TAG}
echo ""

# Display labels
echo -e "${BLUE}🏷️  Image Labels (Demo-specific):${NC}"
docker inspect ${IMAGE_NAME}:${IMAGE_TAG} --format='{{range $k, $v := .Config.Labels}}{{if or (eq $k "demo.instruction") (eq $k "demo.purpose") (eq $k "org.opencontainers.image.title")}}   {{printf "%s = %s\n" $k $v}}{{end}}{{end}}'
echo ""

# Run the container
echo -e "${BLUE}🚀 Starting container: ${CONTAINER_NAME}${NC}"
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

# Wait for container
sleep 3

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
    
    # Verify files were copied
    echo -e "${BLUE}📁 Verifying COPY instruction worked:${NC}"
    echo -e "${GREEN}   Main index.html:${NC}"
    docker exec ${CONTAINER_NAME} ls -lh /usr/share/nginx/html/index.html
    echo -e "${GREEN}   App files directory:${NC}"
    docker exec ${CONTAINER_NAME} ls -lh /usr/share/nginx/html/app-files/
    echo ""
    
    # Success message
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  🎉 SUCCESS!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}🌐 Access your application:${NC}"
    echo -e "   ${GREEN}http://localhost:${HOST_PORT}${NC}"
    echo ""
    echo -e "${BLUE}📝 Click these topics to learn:${NC}"
    echo -e "   🐳 Docker Build"
    echo -e "   ▶️ Docker Run"
    echo -e "   🏷️ Docker Tag"
    echo -e "   📤 Docker Push"
    echo -e "   🏷️ Docker Labels"
    echo ""
    echo -e "${BLUE}📊 Useful Commands:${NC}"
    echo -e "   View logs:        ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
    echo -e "   Follow logs:      ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "   Stop container:   ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "   Start container:  ${YELLOW}docker start ${CONTAINER_NAME}${NC}"
    echo -e "   Remove container: ${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
    echo -e "   View labels:      ${YELLOW}docker inspect ${CONTAINER_NAME} | jq '.[0].Config.Labels'${NC}"
    echo ""
    echo -e "${BLUE}🎓 Learning Point:${NC}"
    echo -e "   This demo uses ${GREEN}COPY${NC} instruction (not ADD)"
    echo -e "   COPY is the recommended way to copy files!"
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
