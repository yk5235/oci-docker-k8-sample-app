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
echo "✅ Kubernetes Cleanup Complete!"
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

# Ask about OCI Registry cleanup
echo "========================================"
echo "OCI Container Registry Cleanup"
echo "========================================"
echo ""
read -p "Do you want to remove Docker images from OCI Registry? (yes/no): " CLEANUP_IMAGES

if [ "$CLEANUP_IMAGES" = "yes" ]; then
    CONFIG_FILE="$(dirname "$0")/.registry-config"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        echo "⚠ Registry configuration not found"
        echo "You'll need to delete images manually from OCI Console:"
        echo "  1. Go to OCI Console → Developer Services → Container Registry"
        echo "  2. Find and delete these repositories:"
        echo "     - mongodb-customer"
        echo "     - backend-customer"
        echo "     - frontend-customer"
        exit 0
    fi
    
    source "$CONFIG_FILE"
    
    echo ""
    echo "Registry Configuration:"
    echo "  Region: $REGION"
    echo "  Namespace: $TENANCY_NAMESPACE"
    echo "  Compartment: $COMPARTMENT_ID"
    echo ""
    
    # Function to delete repository
    delete_repo() {
        local repo_name=$1
        echo "Deleting repository: $repo_name"
        
        # Get repository OCID
        REPO_OCID=$(oci artifacts container repository list \
            --compartment-id "$COMPARTMENT_ID" \
            --display-name "$repo_name" \
            --query 'data.items[0].id' \
            --raw-output 2>/dev/null)
        
        if [ -z "$REPO_OCID" ] || [ "$REPO_OCID" = "null" ]; then
            echo "  ℹ Repository '$repo_name' not found or already deleted"
            return 0
        fi
        
        # Delete repository
        oci artifacts container repository delete \
            --repository-id "$REPO_OCID" \
            --force \
            2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Repository '$repo_name' deleted"
        else
            echo "  ✗ Failed to delete '$repo_name' (may require manual deletion)"
        fi
    }
    
    echo "Deleting repositories from OCI Registry..."
    echo ""
    
    delete_repo "mongodb-customer"
    delete_repo "backend-customer"
    delete_repo "frontend-customer"
    
    echo ""
    echo "✅ OCI Registry cleanup complete!"
    echo ""
    echo "🔍 Verify in OCI Console:"
    echo "  OCI Console → Developer Services → Container Registry"
    echo ""
    
    # Clean up local config
    echo "Removing local registry configuration..."
    rm -f "$CONFIG_FILE"
    echo "✓ Local configuration removed"
    
else
    echo ""
    echo "Skipped OCI Registry cleanup"
    echo ""
    echo "Images remain in OCI Registry:"
    echo "  - mongodb-customer"
    echo "  - backend-customer"
    echo "  - frontend-customer"
    echo ""
    echo "To delete them later:"
    echo "  1. Go to OCI Console → Developer Services → Container Registry"
    echo "  2. Select each repository and delete"
    echo "  OR run this script again and choose 'yes'"
fi

echo ""
echo "========================================"
echo "Cleanup Summary"
echo "========================================"
echo ""
echo "✅ Kubernetes Resources: Deleted"
echo "$([ "$CLEANUP_IMAGES" = "yes" ] && echo "✅ OCI Registry Images: Deleted" || echo "⚠ OCI Registry Images: Not deleted")"
echo ""
echo "Next steps:"
echo "  - Verify LoadBalancer deletion in OCI Console"
echo "  - Check OCI Registry if you kept images"
echo "  - You can redeploy anytime with ./scripts/k8s/03-deploy-all.sh"
echo ""
echo "========================================"
echo "Cleanup process finished"
echo "========================================"