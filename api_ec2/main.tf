provider "aws" {
  profile = "default"
  region  = "us-east-1"
}
variable "fn_version" {
  default = "1.0.1"
}

resource "aws_lambda_function" "function" {
  function_name = "bespin_report_ec2"

  s3_bucket = "ossus-repository"
  s3_key    = "v${var.fn_version}/function.zip"

  handler = "function.lambda_handler"
  runtime = "python3.7"

  role = aws_iam_role.lambda_exec.arn
}
resource "aws_iam_role" "lambda_exec" {
  name = "bespin_report_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_api_gateway_rest_api" "bespin_report_ec2" {
  name        = "bespin_report_ec2"
  description = "Terraformed api for ec2 report data"
}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.bespin_report_ec2.id
  parent_id   = aws_api_gateway_rest_api.bespin_report_ec2.root_resource_id
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.bespin_report_ec2.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.bespin_report_ec2.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.bespin_report_ec2.id
  resource_id   = aws_api_gateway_rest_api.bespin_report_ec2.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.bespin_report_ec2.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}
resource "aws_api_gateway_deployment" "bespin_report_ec2" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.bespin_report_ec2.id
  stage_name  = "test"
}
resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.bespin_report_ec2.execution_arn}/*/*"
}
output "base_url" {
  value = aws_api_gateway_deployment.bespin_report_ec2.invoke_url
}


