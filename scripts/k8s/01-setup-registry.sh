#!/bin/bash
set -e

echo "========================================"
echo "Setting Up OCI Container Registry"
echo "========================================"

# Configuration - UPDATE THESE VALUES
# REGION="ap-singapore-1"  # Your OCI region
# TENANCY_NAMESPACE="your-tenancy-namespace"  # Your tenancy namespace (Object Storage Namespace)
# COMPARTMENT_ID="ocid1.compartment.oc1..your-compartment-id"  # Your compartment OCID
REGION="ap-singapore-1"  # Your OCI region
TENANCY_NAMESPACE="axhhij4fyswp"  # Your tenancy namespace
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaae2tjxljh2xp6ar62qtucfltuvvfwu5nlmhkftezacssbj26ccnzq"  # Your compartment OCID

# Repository names
REPO_MONGODB="mongodb-customer"
REPO_BACKEND="backend-customer"
REPO_FRONTEND="frontend-customer"

echo -e "\n📋 Configuration:"
echo "Region: $REGION"
echo "Tenancy Namespace: $TENANCY_NAMESPACE"
echo "Compartment: $COMPARTMENT_ID"

# Validation
if [[ "$TENANCY_NAMESPACE" == "your-tenancy-namespace" ]]; then
    echo ""
    echo "❌ ERROR: Please update TENANCY_NAMESPACE in this script"
    echo ""
    echo "To find your tenancy namespace:"
    echo "1. Go to OCI Console"
    echo "2. Click on your profile icon (top right)"
    echo "3. Click 'Tenancy: <your-tenancy-name>'"
    echo "4. Look for 'Object Storage Namespace' field"
    echo ""
    exit 1
fi

if [[ "$COMPARTMENT_ID" == "ocid1.compartment.oc1..your-compartment-id" ]]; then
    echo ""
    echo "❌ ERROR: Please update COMPARTMENT_ID in this script"
    echo ""
    echo "To find your compartment OCID:"
    echo "1. Go to OCI Console → Identity & Security → Compartments"
    echo "2. Find your compartment"
    echo "3. Copy the OCID"
    echo ""
    exit 1
fi

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
    echo ""
    echo "To get kubeconfig:"
    echo "1. Go to OCI Console → Developer Services → Kubernetes Clusters (OKE)"
    echo "2. Click on your cluster"
    echo "3. Click 'Access Cluster'"
    echo "4. Follow the instructions to set up kubectl"
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
echo "📝 To create an Auth Token:"
echo "1. Go to OCI Console"
echo "2. Click your profile icon → User Settings"
echo "3. Under Resources → Auth Tokens"
echo "4. Click 'Generate Token'"
echo "5. Give it a description (e.g., 'k8s-deployment')"
echo "6. Copy the generated token (you won't see it again!)"
echo ""
echo "📝 Your OCI Username is usually your email address or:"
echo "   Format: oracleidentitycloudservice/<your-email>"
echo "   Example: oracleidentitycloudservice/john.doe@company.com"
echo ""
echo "   OR for federated users, it might be just your email"
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
    echo ""
    echo "Common issues:"
    echo "1. Incorrect username format - should be: ${TENANCY_NAMESPACE}/<username>"
    echo "2. Invalid Auth Token"
    echo "3. Auth Token expired"
    echo ""
    echo "Please verify your credentials and try again"
    exit 1
fi

# Create repositories in OCI Registry
echo -e "\n📦 Creating repositories in OCI Registry..."

create_repo() {
    local repo_name=$1
    echo "Creating repository: $repo_name"
    
    # Try to create repository
    oci artifacts container repository create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$repo_name" \
        --is-public false \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Repository '$repo_name' created"
    else
        echo "  ℹ Repository '$repo_name' may already exist (this is OK)"
    fi
}

create_repo "$REPO_MONGODB"
create_repo "$REPO_BACKEND"
create_repo "$REPO_FRONTEND"

echo "✓ Repositories created/verified"

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
echo "  - Repositories created:"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_MONGODB}"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_BACKEND}"
echo "    • ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${REPO_FRONTEND}"
echo "  - Kubernetes secret 'oci-registry-secret' created in 'customer-app' namespace"
echo "  - Configuration saved to: $CONFIG_FILE"
echo ""
echo "🚀 Next step: Run ./02-build-and-push.sh"
echo "========================================"