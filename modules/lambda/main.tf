locals {
  function_name = "${var.project_name}-${var.environment}-${var.lambda_name}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

data "archive_file" "this" {
  type        = "zip"
  source_file = var.source_file
  source_dir  = var.source_dir
  output_path = var.output_path
  excludes    = var.source_dir != null ? var.excludes : null
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  role    = var.role_arn
  handler = var.handler
  runtime = var.runtime

  architectures                  = var.architectures
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = merge(
      {
        ENVIRONMENT  = var.environment
        PROJECT_NAME = var.project_name
      },
      var.environment_variables
    )
  }

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }

  tags = local.common_tags
}
