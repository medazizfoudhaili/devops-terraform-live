# Build Lambda deployment package (PowerShell)
Write-Host "Creating Lambda deployment package..."
Compress-Archive -Path index.py -DestinationPath lambda_function_payload.zip -Force
Write-Host "✓ lambda_function_payload.zip created successfully"
