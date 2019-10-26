provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_dynamodb_table" "bespin_report_ec2" {
  name = "bespin_report_ec2"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  hash_key = "instance"
#   range_key = 

  attribute {
      name = "instance"
      type = "S"
  }
}