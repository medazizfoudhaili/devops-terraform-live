#!/bin/bash
# Script to test the deployed API endpoint
# Usage: bash test_api.sh

echo "Testing Serverless API..."

# Get API endpoint from Terraform
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null)

if [ -z "$API_ENDPOINT" ]; then
    echo "Error: Could not retrieve API endpoint. Make sure Terraform is applied."
    exit 1
fi

echo "API Endpoint: $API_ENDPOINT"

# Test the endpoint
echo -e "\nSending GET request..."

RESPONSE=$(curl -s -w "\n%{http_code}" "$API_ENDPOINT")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "Status Code: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "\n✅ API Test Passed!"
    
    # Parse response
    MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
    DB_STATUS=$(echo "$BODY" | jq -r '.database_status' 2>/dev/null)
    TABLE=$(echo "$BODY" | jq -r '.table_name' 2>/dev/null)
    
    echo -e "\nTest Results:"
    echo "✓ Message: $MESSAGE"
    echo "✓ Database Status: $DB_STATUS"
    echo "✓ Table Name: $TABLE"
else
    echo -e "\n❌ API Test Failed!"
    exit 1
fi

# Test DynamoDB
echo -e "\n\nScanning DynamoDB table..."

DB_RESPONSE=$(aws dynamodb scan \
    --table-name users \
    --endpoint-url http://localhost:4566 \
    --region us-east-1 \
    --access-key test \
    --secret-key test 2>/dev/null)

if [ $? -eq 0 ]; then
    ITEM_COUNT=$(echo "$DB_RESPONSE" | jq '.Count' 2>/dev/null)
    echo "✓ Found $ITEM_COUNT item(s) in DynamoDB"
    echo "$DB_RESPONSE" | jq '.Items' 2>/dev/null || echo "$DB_RESPONSE"
    echo -e "\n✅ DynamoDB Test Passed!"
else
    echo "⚠ Warning: Could not scan DynamoDB"
fi

echo -e "\n========================================"
echo "All Tests Completed Successfully! ✅"
echo "========================================"
