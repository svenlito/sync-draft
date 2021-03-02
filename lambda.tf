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
