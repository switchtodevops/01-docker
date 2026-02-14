#!/bin/bash

# Custom Nginx Docker Build and Run Script
# This script builds and runs the custom Nginx container

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="custom-nginx"
IMAGE_TAG="1.29.5"
CONTAINER_NAME="my-nginx"
HOST_PORT="8080"
CONTAINER_PORT="80"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Custom Nginx Docker Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    echo -e "${YELLOW}Please install Docker first: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed${NC}"
echo ""

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}🛑 Stopping existing container: ${CONTAINER_NAME}${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Removing existing container: ${CONTAINER_NAME}${NC}"
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    echo ""
fi

# Build the Docker image
echo -e "${BLUE}🔨 Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
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

# Wait a moment for container to fully start
sleep 2

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ Container is running!${NC}"
    echo ""
    
    # Display container information
    echo -e "${BLUE}📦 Container Details:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Display access information
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  🎉 SUCCESS!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}🌐 Access your Nginx server at:${NC}"
    echo -e "   ${GREEN}http://localhost:${HOST_PORT}${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "   View logs:        ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
    echo -e "   Follow logs:      ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "   Stop container:   ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "   Start container:  ${YELLOW}docker start ${CONTAINER_NAME}${NC}"
    echo -e "   Remove container: ${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
    echo -e "   Enter container:  ${YELLOW}docker exec -it ${CONTAINER_NAME} sh${NC}"
    echo ""
    
    # Test the endpoint
    echo -e "${BLUE}🔍 Testing HTTP endpoint...${NC}"
    sleep 1
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HOST_PORT} | grep -q "200"; then
        echo -e "${GREEN}✅ HTTP endpoint is responding!${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP endpoint test failed (container may still be starting)${NC}"
    fi
    echo ""
    
else
    echo -e "${RED}❌ Container failed to start!${NC}"
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete! 🎊${NC}"
echo -e "${GREEN}========================================${NC}"
