#!/bin/bash
set -e

CONTAINER_NAME="mongodb-customer"
IMAGE_NAME="mongodb-customer:latest"
MONGO_PORT=27017

echo "Checking if image exists..."
if ! docker images | grep -q mongodb-customer; then
  echo "Image not found. Building image first..."
  ./build.sh
fi

# Stop and remove existing container if it exists
echo "Removing old container if exists..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

echo "Starting MongoDB 5.0 container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${MONGO_PORT}:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=mongo \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -e MONGO_INITDB_DATABASE=customerDB \
  -v mongodb_data:/data/db \
  ${IMAGE_NAME}

echo "MongoDB container started successfully"
echo "Connection string: mongodb://mongo:password@localhost:${MONGO_PORT}/customerDB?authSource=admin"

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
for i in {1..30}; do
  # MongoDB 5.0+ uses 'mongosh'
  if docker exec ${CONTAINER_NAME} mongosh --eval "db.adminCommand('ping')" --quiet 2>/dev/null; then
    echo "✓ MongoDB is ready!"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠ MongoDB took longer than expected, but container is running"
    echo "You can check logs with: docker logs ${CONTAINER_NAME}"
  else
    echo "Waiting... ($i/30)"
    sleep 2
  fi
done

# Show container status
echo ""
echo "Container Status:"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test MongoDB connection and show version
echo ""
echo "Testing MongoDB connection..."
docker exec ${CONTAINER_NAME} mongosh --eval "db.version()" --quiet 2>/dev/null && \
  echo "✓ MongoDB connection successful!" || \
  echo "⚠ Could not verify connection, but container is running"