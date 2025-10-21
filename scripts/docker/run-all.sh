#!/bin/bash
set -e

echo "========================================"
echo "Starting All Containers"
echo "========================================"

# Get to project root
cd "$(dirname "$0")/../.."

# Check if images exist, build if not
if ! docker images | grep -q mongodb-customer; then
    echo "Images not found. Building first..."
    ./scripts/docker/build-all.sh
fi

# Create network
echo "Creating Docker network..."
docker network create customer-network 2>/dev/null || echo "Network already exists"

# Stop and remove existing containers
docker stop mongodb-customer backend-customer frontend-customer 2>/dev/null || true
docker rm mongodb-customer backend-customer frontend-customer 2>/dev/null || true

echo -e "\n[1/3] Starting MongoDB..."
docker run -d \
  --name mongodb-customer \
  --network customer-network \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=mongo \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -e MONGO_INITDB_DATABASE=customerDB \
  -v mongodb_data:/data/db \
  mongodb-customer:latest

echo "Waiting for MongoDB to be ready..."
sleep 10

echo -e "\n[2/3] Starting Backend..."
docker run -d \
  --name backend-customer \
  --network customer-network \
  -p 3000:3000 \
  -e MONGO_USERNAME=mongo \
  -e MONGO_PASSWORD=password \
  -e MONGO_HOST=mongodb-customer \
  -e MONGO_PORT=27017 \
  -e MONGO_DB=customerDB \
  backend-customer:latest

echo "Waiting for Backend to be ready..."
sleep 5

echo -e "\n[3/3] Starting Frontend..."
docker run -d \
  --name frontend-customer \
  --network customer-network \
  -p 80:80 \
  frontend-customer:latest

echo "Waiting for Frontend to be ready..."
sleep 3

echo -e "\n========================================"
echo "All containers started!"
echo "========================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n========================================"
echo "Access your application:"
echo "  Frontend: http://localhost"
echo "  Backend:  http://localhost:3000"
echo "  MongoDB:  localhost:27017"
echo "========================================"
