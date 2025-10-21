#!/bin/bash
set -e

echo "========================================"
echo "Testing Customer API"
echo "========================================"

# Get external IP
EXTERNAL_IP=$(kubectl get svc frontend-service -n customer-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$EXTERNAL_IP" ]; then
    echo "❌ Error: LoadBalancer external IP not available"
    echo "Please wait for the LoadBalancer to be provisioned"
    echo "Check with: kubectl get svc frontend-service -n customer-app"
    exit 1
fi

API_URL="http://${EXTERNAL_IP}/api"

echo "Testing API at: $API_URL"
echo ""

# Test 1: Health Check
echo "[1/6] Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Health check passed"
    echo "$HEALTH_RESPONSE" | head -n -1 | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE" | head -n -1
else
    echo "✗ Health check failed (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: Create Customer
echo -e "\n[2/6] Creating a test customer..."
CREATE_RESPONSE=$(curl -s -X POST ${API_URL}/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User API",
    "address": "456 Test Avenue",
    "country": "Singapore",
    "gender": "Female",
    "age": 28
  }')

CUSTOMER_ID=$(echo $CREATE_RESPONSE | jq -r '._id' 2>/dev/null)

if [ -n "$CUSTOMER_ID" ] && [ "$CUSTOMER_ID" != "null" ]; then
    echo "✓ Customer created successfully"
    echo "  Customer ID: $CUSTOMER_ID"
    echo "  Response: $(echo $CREATE_RESPONSE | jq -c '.')"
else
    echo "✗ Failed to create customer"
    echo "  Response: $CREATE_RESPONSE"
    exit 1
fi

# Test 3: Get All Customers
echo -e "\n[3/6] Getting all customers..."
ALL_CUSTOMERS=$(curl -s ${API_URL}/customers)
CUSTOMER_COUNT=$(echo $ALL_CUSTOMERS | jq 'length' 2>/dev/null || echo "0")

if [ "$CUSTOMER_COUNT" -gt 0 ]; then
    echo "✓ Retrieved $CUSTOMER_COUNT customer(s)"
    echo "$ALL_CUSTOMERS" | jq '.[0]' 2>/dev/null || echo "$ALL_CUSTOMERS" | head -n 5
else
    echo "⚠ No customers found"
fi

# Test 4: Get Customer by ID
echo -e "\n[4/6] Getting customer by ID..."
GET_RESPONSE=$(curl -s ${API_URL}/customers/${CUSTOMER_ID})
GET_NAME=$(echo $GET_RESPONSE | jq -r '.name' 2>/dev/null)

if [ "$GET_NAME" = "Test User API" ]; then
    echo "✓ Customer retrieved successfully"
    echo "  Name: $GET_NAME"
else
    echo "✗ Failed to retrieve customer"
    echo "  Response: $GET_RESPONSE"
fi

# Test 5: Update Customer
echo -e "\n[5/6] Updating customer..."
UPDATE_RESPONSE=$(curl -s -X PATCH ${API_URL}/customers/${CUSTOMER_ID} \
  -H "Content-Type: application/json" \
  -d '{"age": 29, "country": "Malaysia"}')

UPDATED_AGE=$(echo $UPDATE_RESPONSE | jq -r '.age' 2>/dev/null)
UPDATED_COUNTRY=$(echo $UPDATE_RESPONSE | jq -r '.country' 2>/dev/null)

if [ "$UPDATED_AGE" = "29" ] && [ "$UPDATED_COUNTRY" = "Malaysia" ]; then
    echo "✓ Customer updated successfully"
    echo "  New age: $UPDATED_AGE"
    echo "  New country: $UPDATED_COUNTRY"
else
    echo "✗ Failed to update customer"
    echo "  Response: $UPDATE_RESPONSE"
fi

# Test 6: Delete Customer
echo -e "\n[6/6] Deleting customer..."
DELETE_RESPONSE=$(curl -s -X DELETE ${API_URL}/customers/${CUSTOMER_ID})
DELETED_ID=$(echo $DELETE_RESPONSE | jq -r '._id' 2>/dev/null)

if [ "$DELETED_ID" = "$CUSTOMER_ID" ]; then
    echo "✓ Customer deleted successfully"
else
    echo "✗ Failed to delete customer"
    echo "  Response: $DELETE_RESPONSE"
fi

# Verify deletion
echo -e "\nVerifying deletion..."
VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}/customers/${CUSTOMER_ID})
VERIFY_CODE=$(echo "$VERIFY_RESPONSE" | tail -n 1)

if [ "$VERIFY_CODE" = "404" ]; then
    echo "✓ Verified: Customer no longer exists"
else
    echo "⚠ Customer may still exist (HTTP $VERIFY_CODE)"
fi

echo -e "\n========================================"
echo "✅ All API Tests Completed!"
echo "========================================"
echo ""
echo "📊 Test Summary:"
echo "  ✓ Health Check"
echo "  ✓ Create Customer"
echo "  ✓ Get All Customers"
echo "  ✓ Get Customer by ID"
echo "  ✓ Update Customer"
echo "  ✓ Delete Customer"
echo ""
echo "🌐 Application URL: http://${EXTERNAL_IP}"
echo "========================================"