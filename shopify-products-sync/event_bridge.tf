resource "aws_cloudwatch_event_bus" "sync_products" {
  name = "sync_products"
}

resource "aws_cloudwatch_event_rule" "create_product" {
  name           = "create_product"
  event_bus_name = aws_cloudwatch_event_bus.sync_products.name

  event_pattern = <<EOF
{
  "detail-type": ["product.create"],
  "source": ["co.pmlo.henry"]
}
EOF
}

resource "aws_cloudwatch_event_rule" "update_product_apollo" {
  name           = "update_product_apollo"
  event_bus_name = aws_cloudwatch_event_bus.sync_products.name

  event_pattern = <<EOF
{
  "detail-type": ["product.update"],
  "source": ["co.pmlo.apollo"]
}
EOF
}

resource "aws_cloudwatch_event_rule" "update_product_henry" {
  name           = "update_product_henry"
  event_bus_name = aws_cloudwatch_event_bus.sync_products.name

  event_pattern = <<EOF
{
  "detail-type": ["product.update"],
  "source": ["co.pmlo.henry"]
}
EOF
}


resource "aws_cloudwatch_event_target" "sku_target" {
  rule           = aws_cloudwatch_event_rule.create_product.name
  event_bus_name = aws_cloudwatch_event_bus.sync_products.name
  target_id      = "sku"
  arn            = aws_lambda_function.sku_lambda.arn
}

