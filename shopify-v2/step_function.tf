module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "${random_pet.this.id}-step-function"

  definition = jsonencode(yamldecode(templatefile("sfn.yaml", { sfnARN = module.lambda_function_shopify_push_handler.this_lambda_function_arn })))

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
