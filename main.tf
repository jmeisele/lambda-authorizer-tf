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

data "aws_ecr_repository" "repository" {
  name = "davinci_ecr"
}

data "aws_ecr_image" "authorizer_image" {
  repository_name = data.aws_ecr_repository.repository.name
  image_tag       = "lambda_authorizer"
}

data "aws_ecr_image" "handler_image" {
  repository_name = data.aws_ecr_repository.repository.name
  image_tag       = "lambda_handler"
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs: CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    actions = [
      "ecr:BatchGetImage"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.account_id}:davinci_ecr/*"
    ]
  }
}

data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.authorizer.arn]
  }
}

# IAM policy for logging from a lambda and getting our image from ECR
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.lambda.json
}

# Policy Attachment on the role.
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_lambda_function" "authorizer" {
  function_name = "lambda_authorizer"
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = "${data.aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.authorizer_image.image_digest}"
  package_type  = "Image"
}

resource "aws_lambda_function" "handler" {
  function_name = "lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = "${data.aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.handler_image.image_digest}"
  package_type  = "Image"
}

resource "aws_api_gateway_rest_api" "lambda_api" {
  name = "mock_authorizer_api"
}

resource "aws_api_gateway_authorizer" "demo" {
  name                   = "demo_authorizer"
  rest_api_id            = aws_api_gateway_rest_api.lambda_api.id
  authorizer_type        = "REQUEST"
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  identity_source        = "method.request.header.Authorization"
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_auth_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "default"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}

# resource "aws_api_gateway_resource" "proxy_pred" {
#   rest_api_id = aws_api_gateway_rest_api.lambda_api.id
#   parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
#   path_part   = "customer"
#   #   request_paremeters = {
#   #   }
# }

# resource "aws_api_gateway_method" "method_proxy" {
#   rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
#   resource_id   = aws_api_gateway_resource.proxy_pred.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "api_lambda" {
#   rest_api_id = aws_api_gateway_rest_api.lambda_api.id
#   resource_id = aws_api_gateway_method.method_proxy.resource_id
#   http_method = aws_api_gateway_method.method_proxy.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = var.lambda_func_invoke_arn
#   timeout_milliseconds    = 29000
# }

# # IAM for API
# resource "aws_api_gateway_rest_api_policy" "api_allow_invoke" {
#   rest_api_id = aws_api_gateway_rest_api.lambda_api.id

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": [
#         "execute-api:Invoke"
#       ],
#       "Resource": [
#         "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/*/${aws_api_gateway_method.method_proxy.http_method}${aws_api_gateway_resource.proxy_pred.path}"
#       ]
#     }
#   ]
# }
# EOF
# }