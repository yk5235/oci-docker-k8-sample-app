#!/bin/bash
set -e

IMAGE_NAME="frontend-customer"
IMAGE_TAG="latest"

echo "Building frontend image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Frontend image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"