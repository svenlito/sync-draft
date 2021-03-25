resource "aws_cloudwatch_log_group" "sku_logs" {
  name              = "/aws/lambda/sku"
  retention_in_days = 1
}
