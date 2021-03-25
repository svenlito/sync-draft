resource "aws_dynamodb_table" "products_table" {
  name             = "Products"
  billing_mode     = "PROVISIONED"
  read_capacity    = 20
  write_capacity   = 20
  hash_key         = "ProductId"
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"

  attribute {
    name = "ProductId"
    type = "S"
  }
}
