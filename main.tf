provider "aws" {
  profile = "default"
  region = "us-east-1"
}
resource "aws_lambda_function" "function" {
  function_name = "bespin_report_ec2"

  s3_bucket = "ossus-repository"
  s3_key = "v1.0.0/function.zip"

  handler = "lambda_handler"
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