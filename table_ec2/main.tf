terraform {
    backend "s3" {
        bucket = "coffay-terraform-state"
        key = "bespin_table_ec2"
        region = "us-east-1"
        profile = "default"
    }
}
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
  attribute {
      name = "instance"
      type = "S"
  }
}
variable "fn_version" {
  default = "1.0.0"
}
variable "service" {
  default = "table_ec2" 
}
resource "aws_lambda_function" "function" {
  function_name = "bespin_table_ec2"

  s3_bucket = "ossus-repository"
  s3_key    = "${var.service}/v${var.fn_version}/function.zip"

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
# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
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
            "dynamodb:DescribeReservedCapacityOfferings",
            "dynamodb:ListGlobalTables",
            "dynamodb:ListTables",
            "dynamodb:DescribeReservedCapacity",
            "dynamodb:ListBackups",
            "dynamodb:PurchaseReservedCapacityOfferings",
            "dynamodb:DescribeLimits",
            "dynamodb:ListStreams"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "dynamodb:*",
        "Resource": [
            "arn:aws:dynamodb:us-east-1:483374585662:table/bespin_report_ec2/backup/*",
            "arn:aws:dynamodb:us-east-1:483374585662:table/bespin_report_ec2/index/*",
            "arn:aws:dynamodb:us-east-1:483374585662:table/bespin_report_ec2/stream/*",
            "arn:aws:dynamodb::483374585662:global-table/bespin_report_ec2",
            "arn:aws:dynamodb:us-east-1:483374585662:table/bespin_report_ec2"
        ]
    },
    {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:GetEbsEncryptionByDefault",
                "ec2:DescribeSnapshots",
                "ec2:DescribeHostReservationOfferings",
                "ec2:DescribeTrafficMirrorSessions",
                "ec2:DescribeTrafficMirrorFilters",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeScheduledInstanceAvailability",
                "ec2:DescribeVolumes",
                "ec2:DescribeFpgaImageAttribute",
                "ec2:GetEbsDefaultKmsKeyId",
                "ec2:DescribeExportTasks",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeReservedInstancesListings",
                "ec2:DescribeCapacityReservations",
                "ec2:DescribeClientVpnRoutes",
                "ec2:DescribeSpotFleetRequestHistory",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeVpcClassicLinkDnsSupport",
                "ec2:DescribeIdFormat",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeImportSnapshotTasks",
                "ec2:DescribeVpcEndpointServicePermissions",
                "ec2:GetPasswordData",
                "ec2:DescribeTransitGatewayAttachments",
                "ec2:DescribeScheduledInstances",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeFleets",
                "ec2:DescribeReservedInstancesModifications",
                "ec2:DescribeSubnets",
                "ec2:DescribeMovingAddresses",
                "ec2:DescribeFleetHistory",
                "ec2:DescribePrincipalIdFormat",
                "ec2:DescribeFlowLogs",
                "ec2:DescribeRegions",
                "ec2:DescribeTransitGateways",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DescribeSpotInstanceRequests",
                "ec2:DescribeVpcAttribute",
                "ec2:ExportClientVpnClientCertificateRevocationList",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeTrafficMirrorTargets",
                "ec2:DescribeTransitGatewayRouteTables",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:DescribeVpcEndpointConnections",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeHostReservations",
                "ec2:DescribeBundleTasks",
                "ec2:DescribeClassicLinkInstances",
                "ec2:DescribeIdentityIdFormat",
                "ec2:DescribeVpcEndpointConnectionNotifications",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeFpgaImages",
                "ec2:DescribeVpcs",
                "ec2:DescribeStaleSecurityGroups",
                "ec2:DescribeAggregateIdFormat",
                "ec2:ExportClientVpnClientConfiguration",
                "ec2:DescribeVolumesModifications",
                "ec2:GetHostReservationPurchasePreview",
                "ec2:DescribeClientVpnConnections",
                "ec2:DescribeByoipCidrs",
                "ec2:DescribePlacementGroups",
                "ec2:DescribeInternetGateways",
                "ec2:GetLaunchTemplateData",
                "ec2:SearchTransitGatewayRoutes",
                "ec2:DescribeSpotDatafeedSubscription",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeNetworkInterfacePermissions",
                "ec2:DescribeReservedInstances",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "ec2:DescribeClientVpnEndpoints",
                "ec2:DescribeEgressOnlyInternetGateways",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeVpnConnections",
                "ec2:DescribeReservedInstancesOfferings",
                "ec2:DescribeFleetInstances",
                "ec2:GetTransitGatewayAttachmentPropagations",
                "ec2:DescribeClientVpnTargetNetworks",
                "ec2:DescribeVpcEndpointServiceConfigurations",
                "ec2:DescribePrefixLists",
                "ec2:GetReservedInstancesExchangeQuote",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:DescribeVpcClassicLink",
                "ec2:GetTransitGatewayRouteTablePropagations",
                "ec2:DescribeElasticGpus",
                "ec2:DescribeVpcEndpoints",
                "ec2:DescribeVpnGateways",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstanceAttribute",
                "ec2:GetCapacityReservationUsage",
                "ec2:DescribeDhcpOptions",
                "ec2:GetConsoleOutput",
                "ec2:DescribeSpotPriceHistory",
                "ec2:DescribeNetworkInterfaces",
                "ec2:GetTransitGatewayRouteTableAssociations",
                "ec2:DescribeIamInstanceProfileAssociations",
                "ec2:DescribeTags",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeImportImageTasks",
                "ec2:DescribeNatGateways",
                "ec2:DescribeCustomerGateways",
                "ec2:DescribeSpotFleetRequests",
                "ec2:DescribeHosts",
                "ec2:DescribeImages",
                "ec2:DescribeSpotFleetInstances",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeClientVpnAuthorizationRules",
                "ec2:DescribePublicIpv4Pools",
                "ec2:DescribeTransitGatewayVpcAttachments",
                "ec2:DescribeConversionTasks"
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
resource "aws_cloudwatch_event_rule" "every_day_at_5_am" {
    name = "every_day_at_5_am"
    description = "every_day_at_5_am"
    schedule_expression = "cron(00 5 * * ? *)"
}
resource "aws_cloudwatch_event_target" "every_day_at_5_am" {
    rule = aws_cloudwatch_event_rule.every_day_at_5_am.name
    target_id = "bespin_table_ec2"
    arn = aws_lambda_function.function.arn
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_function" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_day_at_5_am.arn
}
