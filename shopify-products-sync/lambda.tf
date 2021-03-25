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

resource "aws_lambda_function" "stream_trigger_lambda" {
  filename      = "functions/stream_trigger.zip"
  function_name = "stream_trigger"
  role          = aws_iam_role.iam_for_shopify.arn
  handler       = "stream_trigger.handler"

  source_code_hash = filebase64sha256("functions/stream_trigger.zip")

  runtime = "nodejs12.x"

  depends_on = [
    aws_iam_role_policy_attachment.iam_for_shopify_attachment,
    aws_cloudwatch_log_group.sku_logs,
  ]
}

resource "aws_lambda_event_source_mapping" "stream_trigger_mapping" {
  event_source_arn  = aws_dynamodb_table.products_table.stream_arn
  function_name     = aws_lambda_function.stream_trigger_lambda.arn
  starting_position = "LATEST"
}


resource "aws_lambda_permission" "allow_invocation" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sku_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.create_product.arn
}