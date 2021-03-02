resource "aws_cloudwatch_log_group" "aws_cloudwatch_log_group_hello" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 1
}
