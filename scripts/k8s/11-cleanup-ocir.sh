#!/bin/bash
set -e

echo "========================================"
echo "OCI Container Registry Cleanup"
echo "========================================"

# Load configuration
CONFIG_FILE="$(dirname "$0")/.registry-config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "❌ Error: Registry configuration not found"
    echo ""
    echo "This usually means you haven't run the setup script yet,"
    echo "or you've already cleaned up."
    echo ""
    echo "To manually delete images:"
    echo "1. Go to OCI Console"
    echo "2. Navigate to: Developer Services → Container Registry"
    echo "3. Delete these repositories:"
    echo "   - mongodb-customer"
    echo "   - backend-customer"
    echo "   - frontend-customer"
    echo ""
    exit 1
fi

source "$CONFIG_FILE"

echo ""
echo "📋 Configuration:"
echo "  Region: $REGION"
echo "  Namespace: $TENANCY_NAMESPACE"
echo "  Compartment: $COMPARTMENT_ID"
echo ""
echo "This will delete the following repositories and ALL their images:"
echo "  - mongodb-customer"
echo "  - backend-customer"
echo "  - frontend-customer"
echo ""
echo "⚠ WARNING: This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Check if OCI CLI is available
if ! command -v oci &> /dev/null; then
    echo ""
    echo "❌ Error: OCI CLI is not installed or not in PATH"
    echo ""
    echo "Please delete repositories manually:"
    echo "1. Go to OCI Console"
    echo "2. Navigate to: Developer Services → Container Registry"
    echo "3. Select and delete each repository"
    exit 1
fi

echo ""
echo "Starting OCI Registry cleanup..."
echo ""

# Function to list images in a repository
list_images() {
    local repo_name=$1
    echo "📦 Images in $repo_name:"
    
    oci artifacts container image list \
        --compartment-id "$COMPARTMENT_ID" \
        --repository-name "$repo_name" \
        --query 'data.items[*].[version, "digest"]' \
        --output table 2>/dev/null || echo "  No images found or repository doesn't exist"
    echo ""
}

# Function to delete all images in a repository
delete_images() {
    local repo_name=$1
    echo "Deleting all images in: $repo_name"
    
    # Get all image IDs
    IMAGE_IDS=$(oci artifacts container image list \
        --compartment-id "$COMPARTMENT_ID" \
        --repository-name "$repo_name" \
        --query 'data.items[*].id' \
        --raw-output 2>/dev/null)
    
    if [ -z "$IMAGE_IDS" ]; then
        echo "  ℹ No images found in '$repo_name'"
        return 0
    fi
    
    # Delete each image
    for IMAGE_ID in $IMAGE_IDS; do
        oci artifacts container image delete \
            --image-id "$IMAGE_ID" \
            --force \
            2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Deleted image: $IMAGE_ID"
        else
            echo "  ✗ Failed to delete image: $IMAGE_ID"
        fi
    done
}

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
        echo "  ℹ Repository '$repo_name' not found (may already be deleted)"
        return 0
    fi
    
    # Delete repository (this also deletes all images)
    oci artifacts container repository delete \
        --repository-id "$REPO_OCID" \
        --force \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Repository '$repo_name' deleted successfully"
    else
        echo "  ✗ Failed to delete repository '$repo_name'"
        echo "  Try deleting manually from OCI Console"
    fi
    
    echo ""
}

# Show what will be deleted
echo "Listing current images..."
echo ""
list_images "mongodb-customer"
list_images "backend-customer"
list_images "frontend-customer"

echo "Proceeding with deletion..."
echo ""

# Delete repositories (this also deletes all images inside)
delete_repo "mongodb-customer"
delete_repo "backend-customer"
delete_repo "frontend-customer"

echo "========================================"
echo "✅ OCI Registry Cleanup Complete!"
echo "========================================"
echo ""
echo "📝 What was deleted:"
echo "  ✓ Repository: mongodb-customer (and all images)"
echo "  ✓ Repository: backend-customer (and all images)"
echo "  ✓ Repository: frontend-customer (and all images)"
echo ""
echo "🔍 Verify in OCI Console:"
echo "  OCI Console → Developer Services → Container Registry"
echo ""

# Clean up local configuration
echo "Cleaning up local registry configuration..."
rm -f "$CONFIG_FILE"
echo "✓ Configuration file removed: $CONFIG_FILE"

echo ""
echo "========================================"
echo "Note: You can redeploy anytime by running:"
echo "  ./scripts/k8s/01-setup-registry.sh"
echo "  ./scripts/k8s/02-build-and-push.sh"
echo "  ./scripts/k8s/03-deploy-all.sh"
echo "========================================"