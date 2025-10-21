#!/bin/bash
set -e

echo "========================================"
echo "Building and Pushing Docker Images"
echo "========================================"

# Load configuration from previous script
CONFIG_FILE="$(dirname "$0")/.registry-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Error: Registry not configured. Please run ./01-setup-registry.sh first"
    exit 1
fi

# Get to project root
cd "$(dirname "$0")/../.."

# Image version tag (can be overridden with environment variable)
# Usage: IMAGE_TAG=v1.0 ./02-build-and-push.sh
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo ""
echo "💡 Tip: You can specify a custom tag with: IMAGE_TAG=v1.0 $0"
echo ""

echo -e "\n📋 Configuration:"
echo "Region: $REGION"
echo "Tenancy Namespace: $TENANCY_NAMESPACE"
echo "Image Tag: $IMAGE_TAG"

# Build and push MongoDB
echo -e "\n[1/3] Building MongoDB image..."
cd src/mongodb
docker build -t mongodb-customer:${IMAGE_TAG} .
docker tag mongodb-customer:${IMAGE_TAG} ${REGION}.ocir.io/${TENANCY_NAMESPACE}/mongodb-customer:${IMAGE_TAG}

echo "Pushing MongoDB image..."
docker push ${REGION}.ocir.io/${TENANCY_NAMESPACE}/mongodb-customer:${IMAGE_TAG}
echo "✓ MongoDB image pushed successfully"

cd ../..

# Build and push Backend
echo -e "\n[2/3] Building Backend image..."
cd src/backend
docker build -t backend-customer:${IMAGE_TAG} .
docker tag backend-customer:${IMAGE_TAG} ${REGION}.ocir.io/${TENANCY_NAMESPACE}/backend-customer:${IMAGE_TAG}

echo "Pushing Backend image..."
docker push ${REGION}.ocir.io/${TENANCY_NAMESPACE}/backend-customer:${IMAGE_TAG}
echo "✓ Backend image pushed successfully"

cd ../..

# Build and push Frontend
echo -e "\n[3/3] Building Frontend image..."
cd src/frontend
docker build -t frontend-customer:${IMAGE_TAG} .
docker tag frontend-customer:${IMAGE_TAG} ${REGION}.ocir.io/${TENANCY_NAMESPACE}/frontend-customer:${IMAGE_TAG}

echo "Pushing Frontend image..."
docker push ${REGION}.ocir.io/${TENANCY_NAMESPACE}/frontend-customer:${IMAGE_TAG}
echo "✓ Frontend image pushed successfully"

cd ../..

# Verify images in registry
echo -e "\n🔍 Verifying images in OCI Registry..."
echo ""
echo "MongoDB:"
oci artifacts container image list --compartment-id $(cat "$CONFIG_FILE" | grep COMPARTMENT_ID | cut -d'=' -f2) \
    --repository-name mongodb-customer --limit 1 2>/dev/null | grep "display-name" || echo "  - Image pushed (verification skipped)"

echo ""
echo "Backend:"
oci artifacts container image list --compartment-id $(cat "$CONFIG_FILE" | grep COMPARTMENT_ID | cut -d'=' -f2) \
    --repository-name backend-customer --limit 1 2>/dev/null | grep "display-name" || echo "  - Image pushed (verification skipped)"

echo ""
echo "Frontend:"
oci artifacts container image list --compartment-id $(cat "$CONFIG_FILE" | grep COMPARTMENT_ID | cut -d'=' -f2) \
    --repository-name frontend-customer --limit 1 2>/dev/null | grep "display-name" || echo "  - Image pushed (verification skipped)"

echo -e "\n========================================"
echo "✅ All Images Built and Pushed!"
echo "========================================"
echo ""
echo "📝 Pushed images:"
echo "  • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/mongodb-customer:${IMAGE_TAG}"
echo "  • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/backend-customer:${IMAGE_TAG}"
echo "  • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/frontend-customer:${IMAGE_TAG}"
echo ""
echo "🚀 Next step: Run ./03-deploy-all.sh"
echo "========================================"