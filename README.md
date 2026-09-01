# DevOps Terraform + LocalStack Project

A complete serverless API infrastructure using Terraform and LocalStack. This project demonstrates Infrastructure as Code (IaC) best practices with AWS services.

## 🎯 Project Overview

This project creates a fully functional serverless backend with:
- **API Gateway** - REST API endpoint
- **Lambda Function** - Serverless compute with Python
- **DynamoDB** - NoSQL database
- **IAM Role** - Secure permissions management
- **LocalStack** - Local AWS emulation for development/testing

## 📋 Project Structure

```
devops-terraform-live/
├── index.py                    # Lambda handler (Python)
├── main.tf                     # Terraform configuration
├── build.ps1                   # Windows build script
├── build.sh                    # Linux/Mac build script
└── README.md                   # This file
```

## 🚀 Complete Deployment Steps

### Prerequisites
- Terraform installed ([terraform.io](https://www.terraform.io/downloads.html))
- Docker & Docker Compose (for LocalStack)
- Python 3.9+
- AWS CLI (optional, for testing)

### Step 1: Start LocalStack
LocalStack provides a local AWS environment for testing.

```bash
# Using Docker Compose
docker run -d -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack
```

Or create a `docker-compose.yml`:
```yaml
version: '3.8'
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=apigateway,lambda,dynamodb,iam
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
```

Then run: `docker-compose up -d`

### Step 2: Verify Project Files
Ensure all files are in place:
```powershell
Get-ChildItem
```

Expected output:
```
index.py
main.tf
build.ps1
build.sh
README.md
```

### Step 3: Build Lambda Deployment Package
Create the ZIP file containing your Lambda function.

**On Windows (PowerShell):**
```powershell
.\build.ps1
```

**On Linux/Mac (Bash):**
```bash
bash build.sh
```

This creates: `lambda_function_payload.zip`

### Step 4: Initialize Terraform
Download and initialize Terraform providers.

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully configured!
```

### Step 5: Validate Configuration
Check for syntax errors before deployment.

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 6: Plan Deployment
Review what Terraform will create.

```bash
terraform plan -out=tfplan
```

This shows:
- 1 archive file (auto-created ZIP)
- 1 DynamoDB table
- 1 Lambda function
- 1 IAM role
- 1 API Gateway REST API
- 1 API Gateway resource
- 1 API Gateway method
- 1 Lambda integration
- 1 Lambda permission
- 1 API Gateway deployment
- 1 API Gateway stage

### Step 7: Apply Configuration
Deploy the infrastructure to LocalStack.

```bash
terraform apply tfplan
```

You should see output like:
```
aws_dynamodb_table.users: Creating...
aws_iam_role.lambda_role: Creating...
aws_lambda_permission.api_gateway: Creating...
aws_api_gateway_rest_api.my_api: Creating...
...
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

api_endpoint = "http://localhost:4566/restapis/abc123/stages/prod/_user_request_/hello"
dynamodb_table_name = "users"
lambda_function_name = "hello-api"
```

### Step 8: Test the API
Call the deployed endpoint.

**Using curl:**
```bash
curl http://localhost:4566/restapis/<API_ID>/stages/prod/_user_request_/hello
```

**Using PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:4566/restapis/<API_ID>/stages/prod/_user_request_/hello"
```

**Expected Response:**
```json
{
  "message": "Hello from Terraform + LocalStack!",
  "database_status": "User created successfully",
  "table_name": "users"
}
```

### Step 9: Verify DynamoDB Data
Check if the user record was created.

```bash
aws dynamodb scan --table-name users --endpoint-url http://localhost:4566
```

Expected output:
```json
{
  "Items": [
    {
      "id": {"S": "user-123"},
      "name": {"S": "DevOps Engineer"},
      "status": {"S": "Active"}
    }
  ]
}
```

### Step 10: Clean Up
Destroy resources when done (for local testing).

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   API Gateway                           │
│              (REST API Endpoint)                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                  Lambda Function                        │
│            (Python Handler - index.py)                  │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    DynamoDB                             │
│            (NoSQL Database - users table)               │
└─────────────────────────────────────────────────────────┘
```

## 📚 Key Technologies

| Technology | Purpose | Version |
|-----------|---------|---------|
| Terraform | Infrastructure as Code | ~> 5.0 |
| AWS Provider | LocalStack Integration | ~> 5.0 |
| Archive Provider | ZIP Creation | ~> 2.0 |
| Python | Lambda Runtime | 3.9 |
| LocalStack | AWS Emulation | Latest |

## ✅ Project Checklist

- [x] Lambda function created with Python 3.9
- [x] DynamoDB table configured
- [x] IAM role and permissions set up
- [x] API Gateway REST API created
- [x] GET /hello endpoint configured
- [x] Lambda integration with API Gateway
- [x] API Gateway deployment and stage
- [x] Automatic ZIP file creation
- [x] Build scripts (PowerShell & Bash)
- [x] Documentation complete

## 🔧 Troubleshooting

**Error: "Unknown or does not exist" for LocalStack endpoint**
- Ensure LocalStack is running: `docker ps`
- Check endpoint URL is correct: `http://localhost:4566`

**Error: "File not found" for lambda_function_payload.zip**
- Run build script first: `.\build.ps1` or `bash build.sh`

**Error: "stage_name not expected"**
- Use `aws_api_gateway_stage` resource separately from deployment

## 📝 What You Learned

✓ Terraform infrastructure provisioning  
✓ AWS services (Lambda, API Gateway, DynamoDB, IAM)  
✓ Infrastructure as Code best practices  
✓ LocalStack for local AWS development  
✓ CI/CD preparation with automated builds  
✓ RESTful API design  
✓ Serverless architecture  

## 🎓 CV Summary

**Serverless Infrastructure Deployment**
- Designed and deployed a complete serverless API using Terraform and LocalStack
- Configured AWS services: API Gateway, Lambda, DynamoDB, and IAM
- Implemented Infrastructure as Code (IaC) for reproducible deployments
- Created automated build pipelines for Lambda function packaging
- Tested and validated infrastructure locally before production deployment

## 📞 Next Steps

1. Deploy to AWS (change LocalStack endpoints to real AWS)
2. Add CI/CD pipeline (GitHub Actions, GitLab CI)
3. Implement unit tests for Lambda function
4. Add CloudWatch logging and monitoring
5. Set up auto-scaling policies
6. Implement API authentication/authorization

---

**Status**: ✅ Complete and Ready to Deploy
