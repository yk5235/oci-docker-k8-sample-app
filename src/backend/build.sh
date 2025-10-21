#!/bin/bash
set -e

IMAGE_NAME="backend-customer"
IMAGE_TAG="latest"

echo "Building backend image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Backend image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"