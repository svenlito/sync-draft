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
  "account": ["${var.aws_account_id}"],
  "region": ["${var.aws_region}"]
}
EOF
}

resource "aws_cloudwatch_event_target" "aws_cloudwatch_event_target_lambda" {
  rule           = aws_cloudwatch_event_rule.aws_cloudwatch_event_rule_hello.name
  event_bus_name = aws_cloudwatch_event_bus.aws_cloudwatch_event_bus_greetings.name
  target_id      = "SendToLambda"
  arn            = aws_lambda_function.aws_lambda_function_hello.arn
}