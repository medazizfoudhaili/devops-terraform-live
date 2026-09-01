terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Provider pointing to LocalStack
provider "aws" {
  region                   = "us-east-1"
  access_key               = "test"
  secret_key               = "test"
  skip_credentials_validation = true
  skip_metadata_api_check  = true
  skip_requesting_account_id = true

  endpoints {
    apigateway     = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
  }
}

# 1. Automatic Lambda ZIP creation
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.py"
  output_path = "lambda_function_payload.zip"
}

# 2. DynamoDB Table
resource "aws_dynamodb_table" "users" {
  name           = "users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "users-table"
  }
}

# 3. IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 4. Lambda Function
resource "aws_lambda_function" "hello_api" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "hello-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.9"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

# 5. Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

# 6. API Gateway REST API
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "MyAPI"
  description = "My Serverless API"
}

# 7. API Gateway Resource (/hello)
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "hello"
}

# 8. API Gateway Method (GET)
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "GET"
  authorization = "NONE"
}

# 9. API Gateway Method Response
resource "aws_api_gateway_method_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"
}

# 10. Lambda Integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_api.invoke_arn
}

# 11. Integration Response
resource "aws_api_gateway_integration_response" "ok" {
  rest_api_id       = aws_api_gateway_rest_api.my_api.id
  resource_id       = aws_api_gateway_resource.root.id
  http_method       = aws_api_gateway_method.get.http_method
  status_code       = aws_api_gateway_method_response.ok.status_code
  depends_on        = [aws_api_gateway_integration.lambda]
}

# 12. API Gateway Deployment
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  depends_on  = [aws_api_gateway_integration_response.ok]
}

# 12b. API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  stage_name    = "prod"
}

# 13. Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.my_api.id}/stages/prod/_user_request_/hello"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.hello_api.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.users.name
}