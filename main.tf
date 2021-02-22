terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.29.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_cloudwatch_event_bus" "aws_cloudwatch_event_bus_greetings" {
  name = "greetings"
}

resource "aws_cloudwatch_event_rule" "aws_cloudwatch_event_rule_hello" {
  name           = "hello"
  event_bus_name = aws_cloudwatch_event_bus.aws_cloudwatch_event_bus_greetings.name

  event_pattern = <<EOF
{
  "detail-type": ["greetings"],
  "source": ["com.greetings.app"],
  "account": ["521196292520"],
  "region": ["ap-southeast-1"]
}
EOF
}

resource "aws_cloudwatch_event_target" "aws_cloudwatch_event_target_lambda" {
  rule           = aws_cloudwatch_event_rule.aws_cloudwatch_event_rule_hello.name
  event_bus_name = aws_cloudwatch_event_bus.aws_cloudwatch_event_bus_greetings.name
  target_id      = "SendToLambda"
  arn            = aws_lambda_function.aws_lambda_function_hello.arn
}

# Lambda configs
resource "aws_iam_role" "aws_iam_role_lambda" {
  name = "iam_for_lambda"

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

resource "aws_lambda_function" "aws_lambda_function_hello" {
  filename         = var.lambda_function_zip
  function_name    = var.lambda_function_name
  role             = aws_iam_role.aws_iam_role_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(var.lambda_function_zip)
  runtime          = "nodejs12.x"

  depends_on = [
    aws_iam_role_policy_attachment.aws_iam_role_policy_attachment_lambda,
    aws_cloudwatch_log_group.aws_cloudwatch_log_group_hello,
  ]
}

resource "aws_cloudwatch_log_group" "aws_cloudwatch_log_group_hello" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 1
}

resource "aws_iam_policy" "aws_iam_policy_lambda" {
  name        = "lambda_logging"
  path        = "/"
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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_lambda" {
  role       = aws_iam_role.aws_iam_role_lambda.name
  policy_arn = aws_iam_policy.aws_iam_policy_lambda.arn
}
