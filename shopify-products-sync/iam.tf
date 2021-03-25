resource "aws_iam_role" "iam_for_shopify" {
  name = "iam_for_shopify"

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

resource "aws_iam_role_policy_attachment" "iam_for_shopify_attachment" {
  role       = aws_iam_role.iam_for_shopify.name
  policy_arn = aws_iam_policy.iam_for_shopify_policy.arn
}

resource "aws_iam_policy" "iam_for_shopify_policy" {
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
        "logs:PutLogEvents",
        "dynamodb:BatchGetItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "arn:aws:dynamodb:*:*:*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}