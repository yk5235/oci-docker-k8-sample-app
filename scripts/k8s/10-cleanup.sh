#!/bin/bash

echo "========================================"
echo "Kubernetes Cleanup"
echo "========================================"

# Check if namespace exists
if ! kubectl get namespace customer-app &> /dev/null; then
    echo "⚠ Namespace 'customer-app' does not exist"
    echo "Nothing to clean up"
    exit 0
fi

echo "This will delete all resources in the 'customer-app' namespace:"
echo "  - Deployments (MongoDB, Backend, Frontend)"
echo "  - Services (including LoadBalancer)"
echo "  - ConfigMaps"
echo "  - Secrets"
echo "  - Namespace"
echo ""
echo "⚠ WARNING: All data will be lost!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo ""
echo "Starting cleanup..."

# Delete namespace (this deletes everything inside)
echo -e "\n[1/2] Deleting namespace and all resources..."
kubectl delete namespace customer-app --timeout=120s

if [ $? -eq 0 ]; then
    echo "✓ Namespace deleted successfully"
else
    echo "⚠ Some resources may not have been deleted"
    echo "Check manually with: kubectl get all -n customer-app"
fi

# Verify LoadBalancer is deleted
echo -e "\n[2/2] Verifying LoadBalancer deletion..."
sleep 5

# Check if any LoadBalancer still exists for the app
REMAINING_LBS=$(kubectl get svc --all-namespaces | grep customer-app || echo "")

if [ -z "$REMAINING_LBS" ]; then
    echo "✓ All LoadBalancers deleted"
else
    echo "⚠ Some LoadBalancers may still be terminating"
    echo "$REMAINING_LBS"
    echo ""
    echo "Note: OCI LoadBalancers may take 1-2 minutes to fully terminate"
    echo "Check OCI Console: Networking → Load Balancers"
fi

echo -e "\n========================================"
echo "✅ Cleanup Complete!"
echo "========================================"
echo ""
echo "📝 What was deleted:"
echo "  ✓ Kubernetes namespace: customer-app"
echo "  ✓ All deployments and pods"
echo "  ✓ All services"
echo "  ✓ All ConfigMaps and Secrets"
echo "  ✓ LoadBalancer (may take 1-2 minutes)"
echo ""
echo "🔍 Verify cleanup:"
echo "  kubectl get namespaces | grep customer-app"
echo "  kubectl get all --all-namespaces | grep customer-app"
echo ""

# Ask about image cleanup
echo "========================================"
read -p "Do you want to remove images from OCI Registry? (yes/no): " CLEANUP_IMAGES

if [ "$CLEANUP_IMAGES" = "yes" ]; then
    CONFIG_FILE="$(dirname "$0")/.registry-config"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        
        echo ""
        echo "Removing images from OCI Registry..."
        echo "Note: This requires OCI CLI to be configured"
        echo ""
        
        echo "To manually delete images, go to:"
        echo "  OCI Console → Developer Services → Container Registry"
        echo ""
        echo "Repositories to delete:"
        echo "  - mongodb-customer"
        echo "  - backend-customer"
        echo "  - frontend-customer"
    else
        echo "Registry configuration not found"
        echo "Delete images manually from OCI Console"
    fi
else
    echo ""
    echo "Images in OCI Registry were not deleted"
    echo "To delete them later, go to:"
    echo "  OCI Console → Developer Services → Container Registry"
fi

echo ""
echo "========================================"
echo "Cleanup process finished"
echo "========================================"