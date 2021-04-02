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

  name = "${random_pet.this.id}-queue"
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

  name = "${random_pet.this.id}-dlq"

  tags = {
    Name = "${random_pet.this.id}-dlq"
  }
}

resource "aws_sqs_queue_policy" "queue" {
  queue_url = module.queue.this_sqs_queue_id
  policy    = data.aws_iam_policy_document.queue_policy.json
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = module.dlq.this_sqs_queue_id
  policy    = data.aws_iam_policy_document.queue_policy.json
}


data "aws_iam_policy_document" "queue_policy" {
  statement {
    sid     = "events-policy"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = ["*"]
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

module "lambda_function_stream_handler" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "1.44.0"

  function_name = "${random_pet.this.id}-stream-handler"
  description   = "Handle streams from dynamo db"
  handler       = "stream.handler"
  runtime       = "nodejs12.x"

  source_path = "./functions"

  event_source_mapping = {
    dynamodb = {
      event_source_arn  = module.dynamodb_table.this_dynamodb_table_stream_arn
      starting_position = "LATEST"
    }
  }

  allowed_triggers = {
    dynamodb = {
      principal  = "dynamodb.amazonaws.com"
      source_arn = module.dynamodb_table.this_dynamodb_table_stream_arn
    }
  }

  create_current_version_allowed_triggers = false

  # Allow failures to be sent to SQS queue
  attach_policy_statements = true
  policy_statements = {
    sqs_failure = {
      effect    = "Allow",
      actions   = ["sqs:SendMessage"],
      resources = [module.dlq.this_sqs_queue_arn]
    }
  }

  attach_policies    = true
  number_of_policies = 3

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
    "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  ]

  tags = {
    Name = "${random_pet.this.id}-stream-handler"
  }
}


module "lambda_function_shopify_push_handler" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "1.44.0"

  function_name = "${random_pet.this.id}-shopify-push-handler"
  description   = "Handle product push to Shopify"
  handler       = "shopifyPush.handler"
  runtime       = "nodejs12.x"

  source_path = "./functions"

  create_current_version_allowed_triggers = false

  # Allow failures to be sent to SQS queue
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
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  tags = {
    Name = "${random_pet.this.id}-shopify-push-handler"
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

module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "${random_pet.this.id}-step-function"

  definition = <<EOF
{
  "Comment": "Push product details to Shopify and connected systems",
  "StartAt": "PushToShopify",
  "States": {
    "PushToShopify": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${module.lambda_function_shopify_push_handler.this_lambda_function_arn}",
        "Payload": {
          "Input.$": "$"
        }
      },
      "ResultPath": "$.result",
      "OutputPath": "$.result.Payload",
      "Next": "PushToCMS"
    },
    "PushToCMS": {
      "Type": "Pass",
      "Next": "Done"
    },
    "Done": {
      "Type": "Pass",
      "End": true
    }
  }
}
EOF

  service_integrations = {
    lambda = {
      lambda = [module.lambda_function_shopify_push_handler.this_lambda_function_arn]
    }
  }

  type = "STANDARD"

  tags = {
    Name = "${random_pet.this.id}-step-function"
  }
}
