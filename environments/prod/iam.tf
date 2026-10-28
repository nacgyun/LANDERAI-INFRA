locals {
  lambda_names = toset([
    "api_lambda",
    "embedding_lambda",
    "design_plan_lambda",
    "landing_page_variant_lambda",
    "persist_result_lambda",
    "revision_worker_lambda",
  ])

  dynamodb_policy_resources = concat(
    values(module.dynamodb.table_arns),
    module.dynamodb.index_arns
  )

  ssm_parameter_names = toset([
    trimprefix(var.openai_api_key_parameter_name, "/"),
    trimprefix(var.clerk_secret_key_parameter_name, "/"),
  ])
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  for_each = local.lambda_names

  name               = "${var.project_name}-${var.environment}-${each.key}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each = aws_iam_role.lambda_exec

  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:TransactWriteItems",
    ]

    resources = local.dynamodb_policy_resources
  }
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name   = "${var.project_name}-${var.environment}-lambda-dynamodb-access"
  policy = data.aws_iam_policy_document.lambda_dynamodb_access.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  for_each = aws_iam_role.lambda_exec

  role       = each.value.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}

data "aws_iam_policy_document" "lambda_landing_page_s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.landing_page_html.arn}/landing-pages/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.landing_page_html.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["landing-pages/*"]
    }
  }
}

resource "aws_iam_policy" "lambda_landing_page_s3_access" {
  name   = "${var.project_name}-${var.environment}-lambda-landing-page-s3-access"
  policy = data.aws_iam_policy_document.lambda_landing_page_s3_access.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_landing_page_s3_access" {
  for_each = aws_iam_role.lambda_exec

  role       = each.value.name
  policy_arn = aws_iam_policy.lambda_landing_page_s3_access.arn
}

data "aws_iam_policy_document" "api_user_hosting_s3_access" {
  statement {
    actions   = ["s3:DeleteObject", "s3:PutObject"]
    resources = ["${module.user_hosting.bucket_arn}/published/*"]
  }
}

resource "aws_iam_policy" "api_user_hosting_s3_access" {
  name   = "${var.project_name}-${var.environment}-api-user-hosting-s3-access"
  policy = data.aws_iam_policy_document.api_user_hosting_s3_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "api_user_hosting_s3_access" {
  role       = aws_iam_role.lambda_exec["api_lambda"].name
  policy_arn = aws_iam_policy.api_user_hosting_s3_access.arn
}

data "aws_iam_policy_document" "lambda_s3_vectors_access" {
  statement {
    actions = [
      "s3vectors:PutVectors",
      "s3vectors:QueryVectors",
      "s3vectors:GetVectors",
    ]

    resources = [
      "arn:aws:s3vectors:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bucket/${var.s3_vector_bucket_name}/index/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_vectors_access" {
  name   = "${var.project_name}-${var.environment}-lambda-s3-vectors-access"
  policy = data.aws_iam_policy_document.lambda_s3_vectors_access.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_s3_vectors_access" {
  for_each = aws_iam_role.lambda_exec

  role       = each.value.name
  policy_arn = aws_iam_policy.lambda_s3_vectors_access.arn
}

data "aws_iam_policy_document" "lambda_ssm_parameter_access" {
  statement {
    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      for parameter_name in local.ssm_parameter_names :
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${parameter_name}"
    ]
  }
}

resource "aws_iam_policy" "lambda_ssm_parameter_access" {
  name   = "${var.project_name}-${var.environment}-lambda-ssm-parameter-access"
  policy = data.aws_iam_policy_document.lambda_ssm_parameter_access.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_parameter_access" {
  for_each = aws_iam_role.lambda_exec

  role       = each.value.name
  policy_arn = aws_iam_policy.lambda_ssm_parameter_access.arn
}

data "aws_iam_policy_document" "step_functions_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_functions_exec" {
  name               = "${var.project_name}-${var.environment}-landing-page-workflow-exec-role"
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "step_functions_lambda_invoke" {
  statement {
    actions = ["lambda:InvokeFunction"]

    resources = [
      module.embedding_lambda.function_arn,
      module.design_plan_lambda.function_arn,
      module.landing_page_variant_lambda.function_arn,
      module.persist_result_lambda.function_arn,
    ]
  }
}

resource "aws_iam_policy" "step_functions_lambda_invoke" {
  name   = "${var.project_name}-${var.environment}-step-functions-lambda-invoke"
  policy = data.aws_iam_policy_document.step_functions_lambda_invoke.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "step_functions_lambda_invoke" {
  role       = aws_iam_role.step_functions_exec.name
  policy_arn = aws_iam_policy.step_functions_lambda_invoke.arn
}

data "aws_iam_policy_document" "api_start_step_functions_execution" {
  statement {
    actions = ["states:StartExecution"]

    resources = [
      module.landing_page_workflow.state_machine_arn,
    ]
  }
}

resource "aws_iam_policy" "api_start_step_functions_execution" {
  name   = "${var.project_name}-${var.environment}-api-start-step-functions-execution"
  policy = data.aws_iam_policy_document.api_start_step_functions_execution.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "api_start_step_functions_execution" {
  role       = aws_iam_role.lambda_exec["api_lambda"].name
  policy_arn = aws_iam_policy.api_start_step_functions_execution.arn
}

data "aws_iam_policy_document" "api_revision_queue_send" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [module.revision_queue.queue_arn]
  }
}

resource "aws_iam_policy" "api_revision_queue_send" {
  name   = "${var.project_name}-${var.environment}-api-revision-queue-send"
  policy = data.aws_iam_policy_document.api_revision_queue_send.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "api_revision_queue_send" {
  role       = aws_iam_role.lambda_exec["api_lambda"].name
  policy_arn = aws_iam_policy.api_revision_queue_send.arn
}

data "aws_iam_policy_document" "revision_worker_sqs_access" {
  statement {
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    resources = [module.revision_queue.queue_arn]
  }
}

resource "aws_iam_policy" "revision_worker_sqs_access" {
  name   = "${var.project_name}-${var.environment}-revision-worker-sqs-access"
  policy = data.aws_iam_policy_document.revision_worker_sqs_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "revision_worker_sqs_access" {
  role       = aws_iam_role.lambda_exec["revision_worker_lambda"].name
  policy_arn = aws_iam_policy.revision_worker_sqs_access.arn
}
