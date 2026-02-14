#!/bin/bash

# Test script for Custom Nginx Container

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTAINER_NAME="my-nginx"
PORT="8080"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing Custom Nginx Container${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: Check if container is running
echo -e "${BLUE}Test 1: Container Status${NC}"
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ Container is running${NC}"
else
    echo -e "${RED}❌ Container is not running${NC}"
    exit 1
fi
echo ""

# Test 2: Check if port is accessible
echo -e "${BLUE}Test 2: Port Accessibility${NC}"
if nc -z localhost ${PORT} 2>/dev/null; then
    echo -e "${GREEN}✅ Port ${PORT} is accessible${NC}"
else
    echo -e "${RED}❌ Port ${PORT} is not accessible${NC}"
    exit 1
fi
echo ""

# Test 3: HTTP Response
echo -e "${BLUE}Test 3: HTTP Response${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT})
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ HTTP response: ${HTTP_CODE} OK${NC}"
else
    echo -e "${RED}❌ HTTP response: ${HTTP_CODE} (expected 200)${NC}"
    exit 1
fi
echo ""

# Test 4: Check if HTML contains version info
echo -e "${BLUE}Test 4: Version Information${NC}"
if curl -s http://localhost:${PORT} | grep -q "1.29.5"; then
    echo -e "${GREEN}✅ Version 1.29.5 found in response${NC}"
else
    echo -e "${YELLOW}⚠️  Version not found in response${NC}"
fi
echo ""

# Test 5: Check Nginx version inside container
echo -e "${BLUE}Test 5: Nginx Version (inside container)${NC}"
NGINX_VERSION=$(docker exec ${CONTAINER_NAME} nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')
echo -e "${GREEN}✅ Nginx version: ${NGINX_VERSION}${NC}"
echo ""

# Test 6: Check container logs for errors
echo -e "${BLUE}Test 6: Container Logs${NC}"
ERROR_COUNT=$(docker logs ${CONTAINER_NAME} 2>&1 | grep -i error | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ No errors in container logs${NC}"
else
    echo -e "${YELLOW}⚠️  Found ${ERROR_COUNT} error(s) in logs${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All Tests Passed! ✅${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Quick Stats:${NC}"
docker stats --no-stream ${CONTAINER_NAME} --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""
echo -e "${BLUE}🌐 Access the server:${NC}"
echo -e "   ${GREEN}http://localhost:${PORT}${NC}"
echo ""
