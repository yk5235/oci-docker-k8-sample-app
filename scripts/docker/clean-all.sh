#!/bin/bash
set -e

echo "Cleaning up all customer containers and images..."

# Stop containers
./stop-all.sh

# Remove containers
docker rm -f mongodb-customer backend-customer frontend-customer 2>/dev/null || true

# Remove images
docker rmi -f mongodb-customer:latest backend-customer:latest frontend-customer:latest 2>/dev/null || true

echo "Cleanup complete"
echo "Note: Volumes (mongodb_data) preserved. To remove: docker volume rm mongodb_data"
