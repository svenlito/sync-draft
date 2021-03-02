variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "lambda_function_zip" {
  default = "./lambdas/hello.zip"
}

variable "lambda_function_name" {
  default = "hello"
}

variable "bucket_name" {
  type = string
}
