resource "aws_lambda_function" "sku_lambda" {
  filename      = "functions/sku.zip"
  function_name = "sku"
  role          = aws_iam_role.iam_for_shopify.arn
  handler       = "sku.handler"

  source_code_hash = filebase64sha256("functions/sku.zip")


  runtime = "nodejs12.x"

  depends_on = [
    aws_iam_role_policy_attachment.iam_for_shopify_attachment,
    aws_cloudwatch_log_group.sku_logs,
  ]
}


resource "aws_lambda_permission" "allow_invocation" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sku_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.create_product.arn
}