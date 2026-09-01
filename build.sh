#!/bin/bash
# Build Lambda deployment package

echo "Creating Lambda deployment package..."
zip lambda_function_payload.zip index.py
echo "✓ lambda_function_payload.zip created successfully"
