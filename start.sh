#!/bin/bash

# DocsServe - Start Script
# Starts the Docker container based on ENVIRONMENT variable

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}DocsServe - Starting...${NC}"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo -e "${GREEN}✓${NC} Loaded environment variables from .env"
else
    echo -e "${YELLOW}⚠${NC} No .env file found, using defaults"
fi

# Default to production if ENVIRONMENT is not set
ENVIRONMENT=${ENVIRONMENT:-production}

echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"

# Start based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    echo -e "${BLUE}Starting in DEVELOPMENT mode...${NC}"
    echo -e "${YELLOW}➜${NC} Hot-reload enabled for nginx configuration"
    docker compose -f compose.yml -f docker/development-compose.yml up -d
elif [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${BLUE}Starting in PRODUCTION mode...${NC}"
    docker compose up -d
else
    echo -e "${YELLOW}⚠${NC} Unknown ENVIRONMENT value: $ENVIRONMENT"
    echo -e "${YELLOW}⚠${NC} Valid values: production, development"
    echo -e "${BLUE}Defaulting to PRODUCTION mode...${NC}"
    docker compose up -d
fi

echo ""
echo -e "${GREEN}✓${NC} DocsServe started successfully!"
echo -e "${BLUE}➜${NC} Access at: http://localhost:8420"
echo -e "${BLUE}➜${NC} View logs: ${YELLOW}docker compose logs -f${NC}"
echo -e "${BLUE}➜${NC} Stop server: ${YELLOW}./stop.sh${NC}"
