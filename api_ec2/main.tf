terraform {
    backend "s3" {
        bucket = "coffay-terraform-state"
        key = "bespin_api_ec2"
        region = "us-east-1"
        profile = "default"
    }
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}
data "aws_caller_identity" "current" {}
variable "fn_version" {
  default = "1.0.1"
}
variable "service" {
  default = "api_ec2" 
}
variable "table_name" {
  default = "bespin_report_ec2"
}
resource "aws_lambda_function" "function" {
  function_name = "bespin_report_ec2"

  s3_bucket = "ossus-repository"
  s3_key    = "${var.service}/v${var.fn_version}/function.zip"

  handler = "function.lambda_handler"
  runtime = "python3.7"

  role = aws_iam_role.lambda_exec.arn
}
resource "aws_iam_role" "lambda_exec" {
  name = "bespin_api_ec2_role"

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
resource "aws_iam_policy" "lambda_logging" {
  name = "bespin_api_ec2_policy"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
        "Effect": "Allow",
        "Action": [
            "dynamodb:BatchGetItem",
            "dynamodb:ConditionCheckItem",
            "dynamodb:Scan",
            "dynamodb:ListTagsOfResource",
            "dynamodb:Query",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:DescribeGlobalTableSettings",
            "dynamodb:DescribeTable",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeGlobalTable",
            "dynamodb:GetItem",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:DescribeBackup",
            "dynamodb:GetRecords"
        ],
        "Resource": [
            "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.table_name}/backup/*",
            "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.table_name}/index/*",
            "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.table_name}/stream/*",
            "arn:aws:dynamodb::${data.aws_caller_identity.current.account_id}:global-table/${var.table_name}",
            "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "dynamodb:DescribeReservedCapacityOfferings",
            "dynamodb:ListGlobalTables",
            "dynamodb:ListTables",
            "dynamodb:DescribeReservedCapacity",
            "dynamodb:ListBackups",
            "dynamodb:DescribeLimits",
            "dynamodb:ListStreams"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
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


