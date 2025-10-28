#!/bin/bash
set -e

echo "========================================"
echo "Setting Up OCI Container Registry"
echo "========================================"

# Configuration - UPDATE THESE VALUES
REGION="ap-singapore-1"
TENANCY_NAMESPACE="idxkccw2srke"
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaae42xeu7qhnn2yloyqv4focr2kuoyvqdom6ouhmshkghfzvpkswsq"

# Repository names
REPO_MONGODB="mongodb-customer"
REPO_BACKEND="backend-customer"
REPO_FRONTEND="frontend-customer"

echo -e "\n📋 Configuration:"
echo "Region: $REGION"
echo "Tenancy Namespace: $TENANCY_NAMESPACE"
echo "Compartment: $COMPARTMENT_ID"

# Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    echo ""
    echo "❌ Error: OCI CLI is not installed"
    echo "Please install from: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
fi

echo -e "\n✓ OCI CLI is installed"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    exit 1
fi

echo "✓ kubectl is installed"

# Check kubectl connection
if ! kubectl cluster-info &> /dev/null; then
    echo ""
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    echo "Please configure kubectl to access your OKE cluster"
    exit 1
fi

echo "✓ Connected to Kubernetes cluster"

# Get OCI username and auth token
echo ""
echo "========================================"
echo "OCI Authentication Setup"
echo "========================================"
echo ""
echo "You need your OCI username and an Auth Token."
echo ""
echo "📝 Your OCI Username format:"
echo "   Format: oracleidentitycloudservice/<your-email>"
echo "   Example: oracleidentitycloudservice/john.doe@company.com"
echo ""

read -p "Enter your OCI username: " OCI_USERNAME

if [ -z "$OCI_USERNAME" ]; then
    echo "❌ Username cannot be empty"
    exit 1
fi

read -sp "Enter your OCI Auth Token: " OCI_AUTH_TOKEN
echo ""

if [ -z "$OCI_AUTH_TOKEN" ]; then
    echo "❌ Auth Token cannot be empty"
    exit 1
fi

# Login to OCI Registry
echo -e "\n🔐 Logging into OCI Container Registry..."
echo "$OCI_AUTH_TOKEN" | docker login ${REGION}.ocir.io -u ${TENANCY_NAMESPACE}/${OCI_USERNAME} --password-stdin

if [ $? -eq 0 ]; then
    echo "✓ Successfully logged into OCI Registry"
else
    echo ""
    echo "❌ Failed to login to OCI Registry"
    exit 1
fi

# Create repositories in OCI Registry
echo -e "\n📦 Creating repositories in OCI Registry..."

create_repo() {
    local repo_name=$1
    echo ""
    echo "Creating repository: $repo_name"
    
    # Check if repository already exists first
    EXISTING_REPO=$(oci artifacts container repository list \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$repo_name" \
        --query 'data.items[0].id' \
        --raw-output 2>&1)
    
    if [ $? -eq 0 ] && [ -n "$EXISTING_REPO" ] && [ "$EXISTING_REPO" != "null" ]; then
        echo "  ℹ Repository '$repo_name' already exists"
        return 0
    fi
    
    # Try to create repository - show errors this time
    echo "  Creating new repository..."
    CREATE_OUTPUT=$(oci artifacts container repository create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$repo_name" \
        --is-public false 2>&1)
    
    CREATE_STATUS=$?
    
    if [ $CREATE_STATUS -eq 0 ]; then
        echo "  ✓ Repository '$repo_name' created successfully"
    else
        # Check if error is because it already exists
        if echo "$CREATE_OUTPUT" | grep -q "already exists"; then
            echo "  ℹ Repository '$repo_name' already exists (this is OK)"
        else
            echo "  ⚠ Warning: Could not create repository '$repo_name'"
            echo "  Error details: $CREATE_OUTPUT"
            echo "  You may need to create it manually in OCI Console"
        fi
    fi
}

# Create all three repositories
create_repo "$REPO_MONGODB"
create_repo "$REPO_BACKEND"
create_repo "$REPO_FRONTEND"

echo ""
echo "✓ Repository setup completed"

# Create Kubernetes secret for image pull
echo -e "\n🔑 Creating Kubernetes image pull secret..."

# Check if namespace exists
if ! kubectl get namespace customer-app &> /dev/null; then
    echo "Creating namespace: customer-app"
    kubectl create namespace customer-app
else
    echo "Namespace 'customer-app' already exists"
fi

# Delete existing secret if it exists
kubectl delete secret oci-registry-secret -n customer-app 2>/dev/null && echo "Deleted old secret" || true

# Create new secret
kubectl create secret docker-registry oci-registry-secret \
    --docker-server=${REGION}.ocir.io \
    --docker-username=${TENANCY_NAMESPACE}/${OCI_USERNAME} \
    --docker-password=${OCI_AUTH_TOKEN} \
    --docker-email=${OCI_USERNAME} \
    -n customer-app

if [ $? -eq 0 ]; then
    echo "✓ Kubernetes secret created successfully"
else
    echo "❌ Failed to create Kubernetes secret"
    exit 1
fi

# Save configuration for other scripts
CONFIG_FILE="$(dirname "$0")/.registry-config"
cat > "$CONFIG_FILE" << EOF
REGION=$REGION
TENANCY_NAMESPACE=$TENANCY_NAMESPACE
COMPARTMENT_ID=$COMPARTMENT_ID
EOF

echo -e "\n========================================"
echo "✅ Registry Setup Complete!"
echo "========================================"
echo ""
echo "📝 Summary:"
echo "  - Docker logged into OCI Registry"
echo "  - Registry URL: ${REGION}.ocir.io/${TENANCY_NAMESPACE}"
echo "  - Repositories created/verified:"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_MONGODB}"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_BACKEND}"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_FRONTEND}"
echo "  - Kubernetes secret 'oci-registry-secret' created in 'customer-app' namespace"
echo "  - Configuration saved to: $CONFIG_FILE"
echo ""
echo "🚀 Next step: Run ./02-build-and-push.sh"
echo "========================================"