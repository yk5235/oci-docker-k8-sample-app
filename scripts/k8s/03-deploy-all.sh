#!/bin/bash
set -e

echo "========================================"
echo "Deploying to Kubernetes"
echo "========================================"

# Load configuration
CONFIG_FILE="$(dirname "$0")/.registry-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Error: Registry not configured. Please run ./01-setup-registry.sh first"
    exit 1
fi

# Get to project root
cd "$(dirname "$0")/../.."

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    echo "Please configure kubectl to connect to your OKE cluster"
    exit 1
fi

echo "✓ Connected to Kubernetes cluster"

# Update image references in deployment files
echo -e "\n📝 Updating deployment files with registry information..."

# Function to update image references - handles both hardcoded and placeholders
update_images() {
    local file=$1
    
    # Create a temporary file
    local tmpfile="${file}.tmp"
    
    # Fix any hardcoded namespaces first (from any region or namespace)
    # This regex catches: any-region.ocir.io/any-namespace/service-name:tag
    sed "s|image: [a-z0-9-]*\.ocir\.io/[a-zA-Z0-9]*/\(mongodb\|backend\|frontend\)-customer:latest|image: ${REGION}.ocir.io/${TENANCY_NAMESPACE}/\1-customer:latest|g" "$file" > "$tmpfile"
    
    # Then replace any remaining placeholders
    sed -i "s|<REGION>|${REGION}|g" "$tmpfile"
    sed -i "s|<NAMESPACE>|${TENANCY_NAMESPACE}|g" "$tmpfile"
    
    # Move temp file back to original
    mv "$tmpfile" "$file"
    
    echo "  Updated: $file"
}

# Update all deployment files
for file in k8s/mongodb/deployment.yaml k8s/backend/deployment.yaml k8s/frontend/deployment.yaml; do
    if [ -f "$file" ]; then
        update_images "$file"
    else
        echo "  ⚠ Warning: $file not found"
    fi
done

echo "✓ Deployment files updated"

# Verify image references
echo -e "\n🔍 Verifying image references..."
echo "Expected: ${REGION}.ocir.io/${TENANCY_NAMESPACE}/[service]-customer:latest"
echo ""
grep "image:" k8s/*/deployment.yaml | grep -v "#"
echo ""

# Deploy resources
echo -e "\n🚀 Deploying resources to Kubernetes..."

# 1. Create namespace
echo -e "\n[1/6] Creating namespace..."
kubectl apply -f k8s/namespace.yaml
echo "✓ Namespace created"

# Wait a moment for namespace to be ready
sleep 2

# 2. Deploy ConfigMaps
echo -e "\n[2/6] Creating ConfigMaps..."
kubectl apply -f k8s/backend/configmap.yaml
kubectl apply -f k8s/frontend/configmap.yaml
echo "✓ ConfigMaps created"

# 3. Deploy MongoDB
echo -e "\n[3/6] Deploying MongoDB..."
kubectl apply -f k8s/mongodb/deployment.yaml
kubectl apply -f k8s/mongodb/service.yaml
echo "✓ MongoDB deployed"

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/mongodb -n customer-app
echo "✓ MongoDB is ready"

# 4. Deploy Backend
echo -e "\n[4/6] Deploying Backend..."
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml
echo "✓ Backend deployed"

# Wait for Backend to be ready
echo "Waiting for Backend to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/backend -n customer-app
echo "✓ Backend is ready"

# 5. Deploy Frontend
echo -e "\n[5/6] Deploying Frontend..."
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml
echo "✓ Frontend deployed"

# Wait for Frontend to be ready
echo "Waiting for Frontend to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/frontend -n customer-app
echo "✓ Frontend is ready"

# 6. Wait for LoadBalancer to get external IP
echo -e "\n[6/6] Waiting for LoadBalancer external IP..."
echo "This may take 2-3 minutes..."

EXTERNAL_IP=""
for i in {1..60}; do
    EXTERNAL_IP=$(kubectl get svc frontend-service -n customer-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo -n "."
    sleep 5
done

echo ""

if [ -n "$EXTERNAL_IP" ]; then
    echo "✓ LoadBalancer external IP assigned: $EXTERNAL_IP"
else
    echo "⚠ LoadBalancer IP not assigned yet. Check status with:"
    echo "  kubectl get svc frontend-service -n customer-app"
fi

echo -e "\n========================================"
echo "✅ Deployment Complete!"
echo "========================================"
echo ""
echo "📊 Deployment Status:"
kubectl get deployments -n customer-app
echo ""
echo "🌐 Services:"
kubectl get services -n customer-app
echo ""

if [ -n "$EXTERNAL_IP" ]; then
    echo "�� Access your application:"
    echo "  Frontend: http://${EXTERNAL_IP}"
    echo "  Backend API: http://${EXTERNAL_IP}/api/customers"
    echo "  Health Check: http://${EXTERNAL_IP}/api/health"
    echo ""
fi

echo "📝 Useful commands:"
echo "  Check status:    ./scripts/k8s/04-get-status.sh"
echo "  Get access info: ./scripts/k8s/05-get-access-info.sh"
echo "  Test API:        ./scripts/k8s/06-test-api.sh"
echo "  View logs:       ./scripts/k8s/09-view-logs.sh"
echo "========================================"
