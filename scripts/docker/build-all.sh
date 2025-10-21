#!/bin/bash
set -e

echo "========================================"
echo "Building All Docker Images"
echo "========================================"

# Get to project root
cd "$(dirname "$0")/../.."

echo -e "\n[1/3] Building MongoDB..."
cd src/mongodb && docker build -t mongodb-customer:latest . && cd ../..

echo -e "\n[2/3] Building Backend..."
cd src/backend && docker build -t backend-customer:latest . && cd ../..

echo -e "\n[3/3] Building Frontend..."
cd src/frontend && docker build -t frontend-customer:latest . && cd ../..

echo -e "\n========================================"
echo "All images built successfully!"
echo "========================================"
docker images | grep -E "mongodb-customer|backend-customer|frontend-customer"
