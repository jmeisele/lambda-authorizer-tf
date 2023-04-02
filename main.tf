terraform {
  required_version = "~> 1.0"
  cloud {
    hostname     = "app.terraform.io"
    organization = "davinci"
    workspaces {
      name = "lambda-authorizer-tf"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  allowed_account_ids     = [var.account_id]
  access_key              = var.access_key
  secret_key              = var.secret_key
  region                  = var.region
  skip_metadata_api_check = true
}

# resource "aws_iam_role" "iam_for_lambda" {
#   name               = "iam_for_lambda"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# # IAM policy for logging from a lambda and getting our image from ECR, depends on if we need access to dynamoDB
# resource "aws_iam_policy" "iam_policy_for_lambda" {
#   name        = "aws_iam_policy_for_terraform_aws_lambda_role"
#   path        = "/"
#   description = "AWS IAM Policy for managing aws lambda role"
#   policy      = var.access_to_dynamo_db ? local.with_dynamo : local.without_dynamo
# }

# # Policy Attachment on the role.
# resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
#   role       = aws_iam_role.iam_for_lambda.name
#   policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
# }

# data "aws_ecr_repository" "repository" {
#   name = var.ecr_name
# }

# data "aws_ecr_image" "image" {
#   repository_name = var.ecr_name
#   image_tag       = var.ecr_image_tag
# }

# # Create a lambda function from the image we uploaded to ECR
# resource "aws_lambda_function" "lambda_func" {
#   function_name = var.name
#   role          = aws_iam_role.iam_for_lambda.arn
#   image_uri     = "${data.aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.image.image_digest}"
#   depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
#   package_type  = "Image"
# }