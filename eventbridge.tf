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