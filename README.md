# Terraform + LocalStack Serverless API

This project provisions a small AWS-like serverless stack locally with LocalStack and Terraform. It demonstrates Infrastructure as Code, GitHub Actions automation, and a simple API Lambda setup for demo and learning purposes.

## Overview

The stack includes:
- API Gateway
- Lambda
- DynamoDB table
- IAM role
- LocalStack-based AWS emulation
- GitHub Actions workflow for automated validation

The Lambda is intentionally lightweight and returns a success JSON payload so it can be used reliably in LocalStack without requiring a full production-ready database flow.

## Project structure

```text
devops-terraform-live/
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── index.py                       # Lambda handler
├── main.tf                        # Terraform resources
├── docker-compose.yml             # LocalStack local runtime
├── build.sh                       # Lambda package script
├── build.ps1                      # Windows package script
├── test_index.py                  # Python unit tests
├── README.md                      # Project overview
├── QUICKSTART.md                  # Fast local setup
├── DEPLOYMENT.md                  # Detailed deployment guide
├── ARCHITECTURE.md                # Architecture notes
├── requirements.txt               # Python dependencies
├── .gitignore                     # Ignore rules
└── terraform.tfstate*             # Local terraform state (if present)
```

## Prerequisites

- Docker
- Terraform
- Python 3.9+
- Optional: GitHub account for CI usage

## Local start

Start LocalStack with the required Docker socket access:

```bash
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e SERVICES=apigateway,lambda,dynamodb,iam,cloudwatch,logs \
  -e LAMBDA_EXECUTOR=docker \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  localstack/localstack:3.8
```

Then verify health:

```bash
curl http://localhost:4566/_localstack/health
```

## Deploy locally

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

The project outputs:
- `api_endpoint`
- `lambda_function_name`
- `dynamodb_table_name`

## Test the API

```bash
curl "$(terraform output -raw api_endpoint)"
```

Example response:

```json
{
  "message": "Hello from Terraform + LocalStack!",
  "database_status": "User created successfully",
  "table_name": "users",
  "event": "{}"
}
```

## Run Python tests

```bash
python -m pytest -q
```

## CI/CD

The workflow in [.github/workflows/deploy.yml](.github/workflows/deploy.yml) validates:
- Terraform format
- Terraform init/validate/plan/apply
- LocalStack startup and health check
- Python unit tests
- Security scan with Trivy

## Notes

This project is designed as a practical DevOps portfolio example. It focuses on working infrastructure automation and reliable LocalStack-based validation rather than a full production persistence workflow.

## Cleanup

```bash
terraform destroy -auto-approve
```

You can also stop and remove the LocalStack container:

```bash
docker rm -f localstack
```
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
