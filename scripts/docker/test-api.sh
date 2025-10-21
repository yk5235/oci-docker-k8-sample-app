#!/bin/bash
set -e

BACKEND_URL="http://localhost:3000"

echo "========================================"
echo "Testing Customer API"
echo "========================================"

echo -e "\n[1/6] Testing health endpoint..."
curl -s ${BACKEND_URL}/health | grep -q "OK" && echo "✓ Health check passed" || echo "✗ Health check failed"

echo -e "\n[2/6] Creating a customer..."
CREATE_RESPONSE=$(curl -s -X POST ${BACKEND_URL}/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "address": "123 Test St",
    "country": "USA",
    "gender": "Male",
    "age": 28
  }')
CUSTOMER_ID=$(echo $CREATE_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "✓ Customer created with ID: $CUSTOMER_ID"

echo -e "\n[3/6] Getting all customers..."
curl -s ${BACKEND_URL}/customers | grep -q "$CUSTOMER_ID" && echo "✓ Customer found" || echo "✗ Customer not found"

echo -e "\n[4/6] Getting customer by ID..."
curl -s ${BACKEND_URL}/customers/${CUSTOMER_ID} | grep -q "Test User" && echo "✓ Customer retrieved" || echo "✗ Retrieval failed"

echo -e "\n[5/6] Updating customer..."
curl -s -X PATCH ${BACKEND_URL}/customers/${CUSTOMER_ID} \
  -H "Content-Type: application/json" \
  -d '{"age": 29}' | grep -q '"age":29' && echo "✓ Customer updated" || echo "✗ Update failed"

echo -e "\n[6/6] Deleting customer..."
curl -s -X DELETE ${BACKEND_URL}/customers/${CUSTOMER_ID} | grep -q "$CUSTOMER_ID" && echo "✓ Customer deleted" || echo "✗ Delete failed"

echo -e "\n========================================"
echo "All tests completed!"
echo "========================================"
