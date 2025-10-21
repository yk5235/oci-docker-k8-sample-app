#!/bin/bash
set -e

echo "========================================"
echo "Starting with Docker Compose"
echo "========================================"

# Get to project root and go to docker directory
cd "$(dirname "$0")/../../docker"

# Stop any existing containers
docker-compose down 2>/dev/null || true

# Build and start all services
docker-compose up -d --build

echo -e "\nWaiting for services to be healthy..."
sleep 15

# Show status
docker-compose ps

echo -e "\n========================================"
echo "Application is ready!"
echo "  Frontend: http://localhost"
echo "  Backend:  http://localhost:3000"
echo "========================================"

echo -e "\nUseful commands:"
echo "  View logs:    cd docker && docker-compose logs -f"
echo "  Stop:         cd docker && docker-compose stop"
echo "  Restart:      cd docker && docker-compose restart"
echo "  Remove:       cd docker && docker-compose down"
