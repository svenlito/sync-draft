resource "aws_cloudwatch_event_bus" "greetings" {
  name = "greetings"
}

resource "aws_cloudwatch_event_rule" "hello_app_rule" {
  name           = "hello_app"
  event_bus_name = aws_cloudwatch_event_bus.greetings.name

  event_pattern = <<EOF
{
  "detail-type": ["greetings"],
  "source": ["com.greetings.app"],
  "account": ["${var.aws_account_id}"],
  "region": ["${var.aws_region}"]
}
EOF
}

resource "aws_cloudwatch_event_rule" "hello_dev_rule" {
  name           = "hello_dev"
  event_bus_name = aws_cloudwatch_event_bus.greetings.name

  event_pattern = <<EOF
{
  "detail-type": ["greetings"],
  "source": ["com.greetings.dev"],
  "account": ["${var.aws_account_id}"],
  "region": ["${var.aws_region}"]
}
EOF
}

resource "aws_cloudwatch_event_target" "hello_app_logs" {
  rule           = aws_cloudwatch_event_rule.hello_app_rule.name
  event_bus_name = aws_cloudwatch_event_bus.greetings.name
  target_id      = "SendToAppLogs"
  arn            = aws_cloudwatch_log_group.hello_logs.arn
}

resource "aws_cloudwatch_event_target" "hello_dev_logs" {
  rule           = aws_cloudwatch_event_rule.hello_dev_rule.name
  event_bus_name = aws_cloudwatch_event_bus.greetings.name
  target_id      = "SendToDevLogs"
  arn            = aws_cloudwatch_log_group.hello_logs.arn
}