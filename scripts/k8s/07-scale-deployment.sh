#!/bin/bash

echo "========================================"
echo "Scale Kubernetes Deployment"
echo "========================================"

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <deployment> <replicas>"
    echo ""
    echo "Available deployments:"
    echo "  - mongodb"
    echo "  - backend"
    echo "  - frontend"
    echo ""
    echo "Example: $0 backend 3"
    exit 1
fi

DEPLOYMENT=$1
REPLICAS=$2

# Validate deployment name
if [[ ! "$DEPLOYMENT" =~ ^(mongodb|backend|frontend)$ ]]; then
    echo "❌ Error: Invalid deployment name '$DEPLOYMENT'"
    echo "Valid options: mongodb, backend, frontend"
    exit 1
fi

# Validate replicas number
if ! [[ "$REPLICAS" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Replicas must be a number"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment $DEPLOYMENT -n customer-app &> /dev/null; then
    echo "❌ Error: Deployment '$DEPLOYMENT' not found in namespace 'customer-app'"
    exit 1
fi

# Get current replica count
CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -n customer-app -o jsonpath='{.spec.replicas}')

echo ""
echo "Deployment: $DEPLOYMENT"
echo "Current replicas: $CURRENT_REPLICAS"
echo "Target replicas: $REPLICAS"
echo ""

if [ "$CURRENT_REPLICAS" = "$REPLICAS" ]; then
    echo "⚠ Deployment already has $REPLICAS replicas"
    exit 0
fi

# Scale deployment
echo "Scaling deployment..."
kubectl scale deployment $DEPLOYMENT -n customer-app --replicas=$REPLICAS

# Wait for rollout
echo "Waiting for deployment to scale..."
kubectl rollout status deployment/$DEPLOYMENT -n customer-app --timeout=120s

# Show new status
echo -e "\n✅ Scaling complete!"
echo ""
echo "Current status:"
kubectl get deployment $DEPLOYMENT -n customer-app
echo ""
echo "Pods:"
kubectl get pods -n customer-app -l app=$DEPLOYMENT

echo -e "\n========================================"
echo "Deployment scaled successfully"
echo "========================================"