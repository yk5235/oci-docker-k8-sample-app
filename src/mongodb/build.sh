#!/bin/bash
set -e

IMAGE_NAME="mongodb-customer"
IMAGE_TAG="latest"

echo "Building MongoDB image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "MongoDB image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"