#!/bin/bash

echo "========================================"
echo "Application Access Information"
echo "========================================"

# Check if namespace exists
if ! kubectl get namespace customer-app &> /dev/null; then
    echo "❌ Namespace 'customer-app' does not exist"
    echo "Please run ./03-deploy-all.sh first"
    exit 1
fi

# Get LoadBalancer external IP
echo -e "\n🔍 Checking LoadBalancer status..."
EXTERNAL_IP=$(kubectl get svc frontend-service -n customer-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$EXTERNAL_IP" ]; then
    echo "⚠ LoadBalancer external IP not yet assigned"
    echo ""
    echo "Status:"
    kubectl get svc frontend-service -n customer-app
    echo ""
    echo "This usually takes 2-3 minutes. Please wait and try again."
    echo "You can watch the status with:"
    echo "  kubectl get svc frontend-service -n customer-app -w"
    exit 0
fi

echo "✓ LoadBalancer external IP: $EXTERNAL_IP"

# Test connectivity
echo -e "\n🧪 Testing connectivity..."

# Test frontend
if curl -s -o /dev/null -w "%{http_code}" http://${EXTERNAL_IP} | grep -q "200"; then
    FRONTEND_STATUS="✓ Accessible"
else
    FRONTEND_STATUS="⚠ Not accessible (may still be starting)"
fi

# Test backend health
if curl -s -o /dev/null -w "%{http_code}" http://${EXTERNAL_IP}/api/health | grep -q "200"; then
    BACKEND_STATUS="✓ Healthy"
else
    BACKEND_STATUS="⚠ Not healthy (may still be starting)"
fi

echo -e "\n========================================"
echo "📍 Access Information"
echo "========================================"
echo ""
echo "🌐 Frontend Web Interface:"
echo "   URL: http://${EXTERNAL_IP}"
echo "   Status: $FRONTEND_STATUS"
echo ""
echo "🔌 Backend API Endpoints:"
echo "   Base URL: http://${EXTERNAL_IP}/api"
echo "   Health: http://${EXTERNAL_IP}/api/health"
echo "   Customers: http://${EXTERNAL_IP}/api/customers"
echo "   Status: $BACKEND_STATUS"
echo ""
echo "========================================"
echo ""
echo "💡 Quick Test Commands:"
echo ""
echo "# Check backend health"
echo "curl http://${EXTERNAL_IP}/api/health"
echo ""
echo "# Get all customers"
echo "curl http://${EXTERNAL_IP}/api/customers"
echo ""
echo "# Create a customer"
echo "curl -X POST http://${EXTERNAL_IP}/api/customers \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{
    \"name\": \"John Doe\",
    \"address\": \"123 Main St\",
    \"country\": \"USA\",
    \"gender\": \"Male\",
    \"age\": 30
  }'"
echo ""
echo "========================================"
echo ""
echo "📝 Additional Commands:"
echo "  Run API tests: ./scripts/k8s/06-test-api.sh"
echo "  View logs:     ./scripts/k8s/09-view-logs.sh"
echo "  Check status:  ./scripts/k8s/04-get-status.sh"
echo "========================================"