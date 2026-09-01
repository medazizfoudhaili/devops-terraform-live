# Deployment Guide

Complete step-by-step guide to deploy this serverless infrastructure.

## Prerequisites

- **Terraform** >= 1.0 ([Download](https://www.terraform.io/downloads.html))
- **Docker & Docker Compose** (for LocalStack)
- **Python** 3.9+ (for Lambda function)
- **Git** (for version control)
- **AWS CLI** (optional, for manual testing)

## Local Development Environment

### Step 1: Start LocalStack

LocalStack emulates AWS services locally for development and testing.

**Option A: Using Docker directly**
```bash
docker run -d -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack:latest
```

**Option B: Using Docker Compose**

Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=apigateway,lambda,dynamodb,iam,cloudwatch
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/health"]
      interval: 10s
      timeout: 5s
      retries: 5
```

Then run:
```bash
docker-compose up -d
```

**Verify LocalStack is running:**
```bash
curl http://localhost:4566/health
```

### Step 2: Install Dependencies

```bash
# Optional: Create Python virtual environment
python -m venv venv
source venv/Scripts/activate  # On Windows
# or
source venv/bin/activate      # On Linux/Mac

# Install test dependencies
pip install pytest boto3
```

### Step 3: Build Lambda Package

Create the ZIP file for Lambda deployment.

**Windows (PowerShell):**
```powershell
.\build.ps1
```

**Linux/Mac (Bash):**
```bash
bash build.sh
```

Expected output: `lambda_function_payload.zip`

### Step 4: Initialize Terraform

```bash
cd devops-terraform-live
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/archive from the dependency lock file
- Using previously-installed hashicorp/aws v5.x.x
- Using previously-installed hashicorp/archive v2.x.x

Terraform has been successfully configured!
```

### Step 5: Validate Configuration

Check Terraform syntax and configuration:

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 6: Plan Deployment

Review what resources will be created:

```bash
terraform plan -out=tfplan
```

Expected output:
```
Plan: 13 to add, 0 to change, 0 to destroy.
```

Resources being created:
- 1 DynamoDB Table
- 1 Lambda Function
- 1 IAM Role
- 1 Lambda Permission
- 1 API Gateway REST API
- 1 API Gateway Resource
- 1 API Gateway Method
- 1 API Gateway Method Response
- 1 API Gateway Integration
- 1 API Gateway Integration Response
- 1 API Gateway Deployment
- 1 API Gateway Stage
- 1 Archive File (for Lambda ZIP)

### Step 7: Apply Configuration

Deploy infrastructure to LocalStack:

```bash
terraform apply tfplan
```

You should see:
```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

api_endpoint = "http://localhost:4566/restapis/abc123xyz/stages/prod/_user_request_/hello"
dynamodb_table_name = "users"
lambda_function_name = "hello-api"
```

### Step 8: Run Unit Tests

```bash
pytest test_index.py -v
```

Expected output:
```
test_index.py::TestLambdaHandler::test_handler_returns_200_status PASSED
test_index.py::TestLambdaHandler::test_handler_returns_json_body PASSED
test_index.py::TestLambdaHandler::test_handler_response_has_message PASSED
test_index.py::TestLambdaHandler::test_handler_response_has_database_status PASSED
test_index.py::TestLambdaHandler::test_handler_response_has_table_name PASSED
test_index.py::TestLambdaHandler::test_handler_response_structure PASSED

===== 6 passed in 0.XX s =====
```

### Step 9: Test the API Endpoint

Get the API endpoint from Terraform outputs:

```bash
API_ENDPOINT=$(terraform output -raw api_endpoint)
echo $API_ENDPOINT
```

**Test with curl:**
```bash
curl $API_ENDPOINT
```

**Test with PowerShell:**
```powershell
$apiEndpoint = terraform output -raw api_endpoint
Invoke-WebRequest -Uri $apiEndpoint
```

**Test with AWS CLI:**
```bash
aws lambda invoke \
  --function-name hello-api \
  --endpoint-url http://localhost:4566 \
  response.json

cat response.json
```

**Expected Response:**
```json
{
  "statusCode": 200,
  "body": "{\"message\": \"Hello from Terraform + LocalStack!\", \"database_status\": \"User created successfully\", \"table_name\": \"users\"}"
}
```

### Step 10: Verify DynamoDB Data

Check if the user record was created:

```bash
aws dynamodb scan \
  --table-name users \
  --endpoint-url http://localhost:4566
```

**Expected Response:**
```json
{
  "Items": [
    {
      "id": {"S": "user-123"},
      "name": {"S": "DevOps Engineer"},
      "status": {"S": "Active"}
    }
  ],
  "Count": 1,
  "ScannedCount": 1
}
```

### Step 11: Clean Up Local Resources

Destroy all created resources:

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.

Stop LocalStack:
```bash
docker-compose down
# or
docker stop <container_id>
```

## CI/CD Pipeline

This project includes GitHub Actions workflows that automatically:

1. **Validate Terraform** - Check syntax and configuration
2. **Run Tests** - Execute unit tests for Lambda function
3. **Security Checks** - Scan for vulnerabilities
4. **Code Quality** - Lint Python code

Workflows are in `.github/workflows/`

## Deployment to Production (AWS)

To deploy to real AWS instead of LocalStack:

1. Update `provider "aws"` block in `main.tf`
   ```hcl
   provider "aws" {
     region = "us-east-1"
     # Remove LocalStack endpoints
   }
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   # Enter your AWS Access Key ID and Secret Access Key
   ```

3. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Add Lambda IAM policy for DynamoDB:
   ```hcl
   resource "aws_iam_role_policy" "lambda_dynamodb" {
     name = "lambda-dynamodb-policy"
     role = aws_iam_role.lambda_role.id
     
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect = "Allow"
         Action = [
           "dynamodb:PutItem",
           "dynamodb:GetItem",
           "dynamodb:Query",
           "dynamodb:Scan"
         ]
         Resource = aws_dynamodb_table.users.arn
       }]
     })
   }
   ```

## Troubleshooting

### LocalStack Connection Error
```
Error: Could not connect to http://localhost:4566
```
**Solution:** Start LocalStack with `docker-compose up -d`

### Lambda ZIP Not Found
```
Error: lambda_function_payload.zip not found
```
**Solution:** Run build script: `.\build.ps1` or `bash build.sh`

### Terraform State Issues
```
Error: Error acquiring the state lock
```
**Solution:** Remove `.terraform/` and run `terraform init` again

### DynamoDB Write Fails
```
Error: The provided table name does not exist
```
**Solution:** Ensure `terraform apply` completed successfully

### API Gateway Invocation Error
```
Error: Forbidden - Invalid API Key
```
**Solution:** Check that `aws_lambda_permission` is properly configured

## Project Structure

```
devops-terraform-live/
├── index.py                    # Lambda handler
├── main.tf                     # Terraform configuration
├── build.ps1                   # Windows build script
├── build.sh                    # Linux/Mac build script
├── test_index.py               # Unit tests
├── .gitignore                  # Git ignore rules
├── .github/workflows/deploy.yml # CI/CD pipeline
├── docker-compose.yml          # LocalStack config
├── DEPLOYMENT.md               # This file
└── README.md                   # Project overview
```

## Performance Tips

1. **Use LocalStack for local development** - Faster feedback loop
2. **Enable Terraform parallelism** - `terraform apply -parallelism=10`
3. **Use separate state files** - Dev/staging/prod isolation
4. **Cache Terraform plugins** - Speed up CI/CD runs

## Security Best Practices

1. ✅ Never commit AWS credentials
2. ✅ Use IAM roles instead of access keys
3. ✅ Enable state file encryption
4. ✅ Use VPC for production Lambdas
5. ✅ Add API Gateway authentication
6. ✅ Enable CloudWatch logging
7. ✅ Regular security scanning

## Next Steps

- [ ] Add CloudWatch logging
- [ ] Implement API authentication
- [ ] Add auto-scaling policies
- [ ] Set up monitoring and alerts
- [ ] Configure custom domain
- [ ] Add request validation
- [ ] Implement error handling
- [ ] Add API documentation (OpenAPI/Swagger)

---

**Last Updated:** September 1, 2026  
**Version:** 1.0.0  
**Status:** Production Ready ✅
