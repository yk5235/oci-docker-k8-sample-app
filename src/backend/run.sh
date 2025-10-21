#!/bin/bash
set -e

CONTAINER_NAME="backend-customer"
IMAGE_NAME="backend-customer:latest"
BACKEND_PORT=3000

# Check if MongoDB is running
if ! docker ps | grep -q mongodb-customer; then
  echo "Error: MongoDB container is not running!"
  echo "Please start MongoDB first: cd ../mongodb && ./run.sh"
  exit 1
fi

# Get MongoDB container IP
MONGO_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-customer)

# Stop and remove existing container if it exists
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

echo "Starting backend container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${BACKEND_PORT}:3000 \
  -e MONGO_USERNAME=mongo \
  -e MONGO_PASSWORD=password \
  -e MONGO_HOST=${MONGO_HOST} \
  -e MONGO_PORT=27017 \
  -e MONGO_DB=customerDB \
  -e NODE_ENV=production \
  ${IMAGE_NAME}

echo "Backend container started successfully"
echo "API available at: http://localhost:${BACKEND_PORT}"

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
sleep 5

# Test health endpoint
curl -s http://localhost:${BACKEND_PORT}/health | grep -q "OK" && \
  echo "Backend is healthy!" || \
  echo "Backend health check failed"