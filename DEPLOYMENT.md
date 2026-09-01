# Deployment Guide

This guide covers the local and CI deployment flow for the Terraform + LocalStack project.

## Prerequisites

- Docker
- Terraform
- Python 3.9+
- Git

## 1. Start LocalStack

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

Check readiness:

```bash
curl http://localhost:4566/_localstack/health
```

## 2. Prepare the Lambda package

```bash
bash build.sh
```

This creates the zip bundle used by Terraform.

## 3. Initialize Terraform

```bash
terraform init
```

## 4. Validate Terraform

```bash
terraform validate
```

## 5. Plan and apply

```bash
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

## 6. Run tests

```bash
python -m pytest -q
```

## 7. Call the API

```bash
curl "$(terraform output -raw api_endpoint)"
```

Expected response:

```json
{
  "message": "Hello from Terraform + LocalStack!",
  "database_status": "User created successfully",
  "table_name": "users",
  "event": "{}"
}
```

## 8. Clean up

```bash
terraform destroy -auto-approve
docker rm -f localstack
```

## CI notes

The GitHub workflow in [.github/workflows/deploy.yml](.github/workflows/deploy.yml) starts LocalStack in a Linux runner and waits for the health endpoint before continuing with Terraform validation and apply steps.

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
