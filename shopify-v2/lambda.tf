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
