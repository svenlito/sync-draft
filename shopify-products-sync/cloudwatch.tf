resource "aws_cloudwatch_log_group" "hello_logs" {
  name              = "/aws/events/${aws_cloudwatch_event_bus.greetings.name}"
  retention_in_days = 1
}
