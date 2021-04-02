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
