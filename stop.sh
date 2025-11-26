#!/bin/bash

# DocsServe - Stop Script
# Stops and removes the Docker container

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}DocsServe - Stopping...${NC}"

docker compose down

echo ""
echo -e "${GREEN}✓${NC} DocsServe stopped successfully!"
echo -e "${BLUE}➜${NC} Start again: ${GREEN}./start.sh${NC}"
