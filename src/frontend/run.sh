#!/bin/bash
set -e

CONTAINER_NAME="frontend-customer"
IMAGE_NAME="frontend-customer:latest"
FRONTEND_PORT=80

# Check if backend is running
if ! docker ps | grep -q backend-customer; then
  echo "Warning: Backend container is not running!"
  echo "Frontend will start but API calls will fail."
  echo "Please start backend first: cd ../backend && ./run.sh"
fi

# Get backend container IP if running
BACKEND_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' backend-customer 2>/dev/null || echo "backend-customer")

# Stop and remove existing container if it exists
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

# Update nginx.conf with backend host
echo "Updating nginx configuration with backend host: ${BACKEND_HOST}"
sed "s/BACKEND_HOST/${BACKEND_HOST}/g" conf/nginx.conf > /tmp/nginx.conf.tmp

echo "Starting frontend container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${FRONTEND_PORT}:80 \
  -v /tmp/nginx.conf.tmp:/etc/nginx/conf.d/default.conf:ro \
  ${IMAGE_NAME}

echo "Frontend container started successfully"
echo "Application available at: http://localhost:${FRONTEND_PORT}"

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
sleep 3

# Test frontend
curl -s http://localhost:${FRONTEND_PORT} > /dev/null && \
  echo "Frontend is accessible!" || \
  echo "Frontend health check failed"

# Clean up temp file
rm -f /tmp/nginx.conf.tmp