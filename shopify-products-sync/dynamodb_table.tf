module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "0.13.0"

  name      = "products"
  hash_key  = "PK"
  range_key = "SK"

  attributes = [
    {
      name = "PK"
      type = "S"
    },
    {
      name = "SK"
      type = "S"
    }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = "${random_pet.this.id}-products-table"
  }
}