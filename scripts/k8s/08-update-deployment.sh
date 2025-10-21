#!/bin/bash

echo "========================================"
echo "Update Kubernetes Deployment"
echo "========================================"

# Load configuration
CONFIG_FILE="$(dirname "$0")/.registry-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Error: Registry not configured"
    exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <deployment> [image-tag]"
    echo ""
    echo "Available deployments:"
    echo "  - mongodb"
    echo "  - backend"
    echo "  - frontend"
    echo "  - all (update all deployments)"
    echo ""
    echo "Example: $0 backend v2"
    echo "Example: $0 all latest"
    exit 1
fi

DEPLOYMENT=$1
IMAGE_TAG="${2:-latest}"

echo "Configuration:"
echo "  Deployment: $DEPLOYMENT"
echo "  Image Tag: $IMAGE_TAG"
echo "  Registry: ${REGION}.ocir.io/${TENANCY_NAMESPACE}"
echo ""

update_deployment() {
    local dep_name=$1
    local image_name=$2
    local container_name=$3
    
    echo "Updating $dep_name deployment..."
    
    # Set new image
    kubectl set image deployment/$dep_name \
        $container_name=${REGION}.ocir.io/${TENANCY_NAMESPACE}/${image_name}:${IMAGE_TAG} \
        -n customer-app
    
    # Wait for rollout
    echo "Waiting for rollout to complete..."
    kubectl rollout status deployment/$dep_name -n customer-app --timeout=180s
    
    if [ $? -eq 0 ]; then
        echo "✓ $dep_name updated successfully"
    else
        echo "✗ Failed to update $dep_name"
        echo ""
        echo "Rollback with: kubectl rollout undo deployment/$dep_name -n customer-app"
        return 1
    fi
}

# Validate and update deployments
if [ "$DEPLOYMENT" = "all" ]; then
    echo "Updating all deployments..."
    echo ""
    
    update_deployment "mongodb" "mongodb-customer" "mongodb"
    echo ""
    update_deployment "backend" "backend-customer" "backend"
    echo ""
    update_deployment "frontend" "frontend-customer" "frontend"
    
elif [[ "$DEPLOYMENT" =~ ^(mongodb|backend|frontend)$ ]]; then
    # Map deployment to image and container names
    case $DEPLOYMENT in
        mongodb)
            IMAGE_NAME="mongodb-customer"
            CONTAINER_NAME="mongodb"
            ;;
        backend)
            IMAGE_NAME="backend-customer"
            CONTAINER_NAME="backend"
            ;;
        frontend)
            IMAGE_NAME="frontend-customer"
            CONTAINER_NAME="frontend"
            ;;
    esac
    
    update_deployment "$DEPLOYMENT" "$IMAGE_NAME" "$CONTAINER_NAME"
else
    echo "❌ Error: Invalid deployment name '$DEPLOYMENT'"
    echo "Valid options: mongodb, backend, frontend, all"
    exit 1
fi

echo -e "\n========================================"
echo "✅ Update Complete!"
echo "========================================"
echo ""
echo "📊 Current Status:"
kubectl get deployments -n customer-app
echo ""
echo "💡 Useful Commands:"
echo "  Check rollout history: kubectl rollout history deployment/<name> -n customer-app"
echo "  Rollback if needed:    kubectl rollout undo deployment/<name> -n customer-app"
echo "  View pods:             kubectl get pods -n customer-app"
echo "========================================"