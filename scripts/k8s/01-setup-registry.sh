#!/bin/bash
set -e

echo "========================================"
echo "Setting Up OCI Container Registry"
echo "========================================"

# Configuration
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
    exit 1
fi

echo "✓ Connected to Kubernetes cluster"

# Get OCI username and auth token
echo ""
echo "========================================"
echo "OCI Authentication Setup"
echo "========================================"
echo ""
echo "📝 Your OCI Username format:"
echo "   Format: oracleidentitycloudservice/<your-email>"
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

# Function to create repository with timeout
create_repo_with_timeout() {
    local repo_name=$1
    local timeout=60  # 60 seconds timeout
    
    echo ""
    echo "Creating repository: $repo_name"
    
    # Use timeout command to prevent hanging
    timeout $timeout oci artifacts container repository create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$repo_name" \
        --is-public false 2>&1 | tee /tmp/oci_output.log
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        echo "  ✓ Repository '$repo_name' created successfully"
        return 0
    elif [ $exit_code -eq 124 ]; then
        echo "  ⚠ Timeout: OCI CLI took too long. Repository might have been created."
        echo "  Checking if repository exists..."
        sleep 2
        check_repo_exists "$repo_name"
        return $?
    else
        # Check if error is because it already exists
        if grep -q "already exists\|AlreadyExists" /tmp/oci_output.log 2>/dev/null; then
            echo "  ℹ Repository '$repo_name' already exists (this is OK)"
            return 0
        else
            echo "  ⚠ Warning: Error creating repository '$repo_name'"
            cat /tmp/oci_output.log
            return 1
        fi
    fi
}

# Function to check if repository exists
check_repo_exists() {
    local repo_name=$1
    
    EXISTING_REPO=$(timeout 30 oci artifacts container repository list \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$repo_name" \
        --query 'data.items[0].id' \
        --raw-output 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$EXISTING_REPO" ] && [ "$EXISTING_REPO" != "null" ]; then
        echo "  ✓ Repository '$repo_name' exists"
        return 0
    else
        echo "  ✗ Repository '$repo_name' does not exist"
        return 1
    fi
}

# Create repositories in OCI Registry
echo -e "\n📦 Creating repositories in OCI Registry..."

# Create all three repositories
create_repo_with_timeout "$REPO_MONGODB"
create_repo_with_timeout "$REPO_BACKEND"
create_repo_with_timeout "$REPO_FRONTEND"

echo ""
echo "✓ Repository setup completed"

# Verify all repositories exist
echo -e "\n🔍 Verifying all repositories..."
check_repo_exists "$REPO_MONGODB"
check_repo_exists "$REPO_BACKEND"
check_repo_exists "$REPO_FRONTEND"

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
