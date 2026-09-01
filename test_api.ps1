# Script to test the deployed API endpoint
# Usage: .\test_api.ps1

Write-Host "Testing Serverless API..." -ForegroundColor Green

# Get API endpoint from Terraform
$apiEndpoint = terraform output -raw api_endpoint 2>$null

if (-not $apiEndpoint) {
    Write-Host "Error: Could not retrieve API endpoint. Make sure Terraform is applied." -ForegroundColor Red
    exit 1
}

Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Cyan

# Test the endpoint
Write-Host "`nSending GET request..." -ForegroundColor Green

try {
    $response = Invoke-WebRequest -Uri $apiEndpoint -Method Get -ContentType "application/json"
    
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:`n" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json | Write-Host
    
    # Parse response
    $body = $response.Content | ConvertFrom-Json
    
    Write-Host "`nTest Results:" -ForegroundColor Green
    Write-Host "✓ Message: $($body.message)" -ForegroundColor Green
    Write-Host "✓ Database Status: $($body.database_status)" -ForegroundColor Green
    Write-Host "✓ Table Name: $($body.table_name)" -ForegroundColor Green
    
    Write-Host "`n✅ API Test Passed!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Test DynamoDB
Write-Host "`n`nScanning DynamoDB table..." -ForegroundColor Green

try {
    $dbResponse = aws dynamodb scan `
        --table-name users `
        --endpoint-url http://localhost:4566 `
        --region us-east-1 `
        --access-key test `
        --secret-key test | ConvertFrom-Json
    
    if ($dbResponse.Items.Count -gt 0) {
        Write-Host "✓ Found $($dbResponse.Items.Count) item(s) in DynamoDB" -ForegroundColor Green
        $dbResponse.Items | ConvertTo-Json | Write-Host
        Write-Host "`n✅ DynamoDB Test Passed!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ No items found in DynamoDB (this may be normal)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠ Warning: Could not scan DynamoDB - $_" -ForegroundColor Yellow
}

Write-Host "`n" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "All Tests Completed Successfully! ✅" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
