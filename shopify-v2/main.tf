terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws    = ">= 3.19"
    random = ">= 3"
  }
}

provider "aws" {
  region = "ap-southeast-1"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "0.1.0"

  bus_name = "${random_pet.this.id}-bus"

  attach_sqs_policy = true
  sqs_target_arns = [
    module.queue.this_sqs_queue_arn,
    module.dlq.this_sqs_queue_arn
  ]

  rules = {
    product_create = {
      description = "create products",
      event_pattern = jsonencode({
        "source" : ["co.pmlo.henry"],
        "detail-type" : ["product.create", "product.update"]
      })
    },
    product_update = {
      description = "update products",
      event_pattern = jsonencode({
        "source" : ["co.pmlo.apollo"],
        "detail-type" : ["product.update"]
      })
    }
  }

  targets = {
    product_create = [
      {
        name            = "send-product-creation-to-queue"
        arn             = module.queue.this_sqs_queue_arn
        dead_letter_arn = module.dlq.this_sqs_queue_arn
        retry_policy = {
          maximum_retry_attempts       = 10
          maximum_event_age_in_seconds = 300
        }
      }
    ]
    product_update = [
      {
        name            = "send-product-updation-to-queue"
        arn             = module.queue.this_sqs_queue_arn
        dead_letter_arn = module.dlq.this_sqs_queue_arn
        retry_policy = {
          maximum_retry_attempts       = 10
          maximum_event_age_in_seconds = 300
        }
      }
    ]
  }

  tags = {
    Name = "${random_pet.this.id}-bus"
  }
}

resource "random_pet" "this" {
  length = 2
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "2.1.0"

  name   = "${random_pet.this.id}-queue"
  policy = data.aws_iam_policy_document.queue_policy.json
  redrive_policy = jsonencode({
    "deadLetterTargetArn" : module.dlq.this_sqs_queue_arn,
    "maxReceiveCount" : 4
  })

  tags = {
    Name = "${random_pet.this.id}-queue"
  }
}

module "dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "2.1.0"

  name   = "${random_pet.this.id}-dlq"
  policy = data.aws_iam_policy_document.queue_policy.json

  tags = {
    Name = "${random_pet.this.id}-dlq"
  }
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    sid     = "events-policy"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

module "lambda_function_sku_handler" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "1.44.0"

  function_name = "${random_pet.this.id}-sku-handler"
  description   = "Insert / update product details in to db"
  handler       = "sku.handler"
  runtime       = "nodejs12.x"

  source_path = "./functions"

  create_current_version_allowed_triggers = false

  event_source_mapping = {
    sqs = {
      event_source_arn = module.queue.this_sqs_queue_arn
    }
  }

  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = module.queue.this_sqs_queue_arn
    }
  }

  attach_policy_statements = true
  policy_statements = {
    sqs_failure = {
      effect    = "Allow",
      actions   = ["sqs:SendMessage"],
      resources = [module.dlq.this_sqs_queue_arn]
    }
  }

  attach_policies    = true
  number_of_policies = 1

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]


  tags = {
    Name = "${random_pet.this.id}-sku-handler"
  }
}

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