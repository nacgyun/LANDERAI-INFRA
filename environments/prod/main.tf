module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  tags = var.tags
}

module "revision_queue" {
  source = "../../modules/revision_queue"

  project_name               = var.project_name
  environment                = var.environment
  visibility_timeout_seconds = 1800
  max_receive_count          = 3
  tags                       = var.tags
}

resource "aws_s3_bucket" "landing_page_html" {
  bucket = var.landing_page_html_bucket_name != "" ? var.landing_page_html_bucket_name : "${var.project_name}-${var.environment}-landing-page-html-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "landing_page_html" {
  bucket = aws_s3_bucket.landing_page_html.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "landing_page_html" {
  bucket = aws_s3_bucket.landing_page_html.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  lambda_environment_variables = {
    APP_ENV                         = var.environment
    REGION_NAME                     = var.aws_region
    CORE_TABLE_NAME                 = module.dynamodb.table_names.core_table
    LANDING_REQUEST_TABLE_NAME      = module.dynamodb.table_names.landing_request
    LANDING_RESULT_TABLE_NAME       = module.dynamodb.table_names.landing_result
    RAG_DESIGN_PLAN_TABLE_NAME      = module.dynamodb.table_names.rag_design_plan
    OPENAI_API_KEY_PARAMETER_NAME   = var.openai_api_key_parameter_name
    CLERK_SECRET_KEY_PARAMETER_NAME = var.clerk_secret_key_parameter_name
    AUTH_MODE                       = var.auth_mode
    CLERK_PUBLISHABLE_KEY           = var.clerk_publishable_key
    CLERK_AUTHORIZED_PARTY          = var.clerk_authorized_party
    S3_BUCKET_NAME                  = aws_s3_bucket.landing_page_html.bucket
    S3_PUBLIC_BASE_URL              = var.landing_page_html_public_base_url
    HOSTING_S3_BUCKET_NAME          = module.user_hosting.bucket_name
    HOSTING_BASE_DOMAIN             = var.user_hosting_base_domain
    S3_VECTOR_BUCKET_NAME           = var.s3_vector_bucket_name
    S3_VECTOR_INDEX_NAME            = var.s3_vector_index_name
    REVISION_MAX_RECEIVE_COUNT      = "3"
  }
}

module "api_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "api_lambda"
  description  = "LANDERAI API Lambda."
  role_arn     = aws_iam_role.lambda_exec["api_lambda"].arn

  source_file = "${path.root}/../../src/api_lambda/handler.py"
  output_path = "${path.root}/build/api_lambda.zip"
  handler     = "app.lambdas.api_handler.lambda_handler"

  memory_size = 512
  timeout     = 30
  environment_variables = merge(
    local.lambda_environment_variables,
    {
      LANDING_PAGE_STATE_MACHINE_ARN = module.landing_page_workflow.state_machine_arn
      REVISION_QUEUE_URL             = module.revision_queue.queue_url
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access,
    aws_iam_role_policy_attachment.api_start_step_functions_execution,
    aws_iam_role_policy_attachment.api_revision_queue_send,
    aws_iam_role_policy_attachment.api_user_hosting_s3_access,
  ]

  tags = var.tags
}

module "embedding_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "embedding_lambda"
  description  = "LANDERAI request embedding Lambda."
  role_arn     = aws_iam_role.lambda_exec["embedding_lambda"].arn

  source_file = "${path.root}/../../src/embedding_lambda/handler.py"
  output_path = "${path.root}/build/embedding_lambda.zip"
  handler     = "app.lambdas.embedding_handler.lambda_handler"

  memory_size           = 512
  timeout               = 60
  environment_variables = local.lambda_environment_variables

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access
  ]

  tags = var.tags
}

module "design_plan_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "design_plan_lambda"
  description  = "LANDERAI design plan generation Lambda."
  role_arn     = aws_iam_role.lambda_exec["design_plan_lambda"].arn

  source_file = "${path.root}/../../src/design_plan_lambda/handler.py"
  output_path = "${path.root}/build/design_plan_lambda.zip"
  handler     = "app.lambdas.design_plan_handler.lambda_handler"

  memory_size           = 1024
  timeout               = 180
  environment_variables = local.lambda_environment_variables

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access
  ]

  tags = var.tags
}

module "landing_page_variant_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "landing_page_variant_lambda"
  description  = "LANDERAI landing page variant generation Lambda."
  role_arn     = aws_iam_role.lambda_exec["landing_page_variant_lambda"].arn

  source_file = "${path.root}/../../src/landing_page_variant_lambda/handler.py"
  output_path = "${path.root}/build/landing_page_variant_lambda.zip"
  handler     = "app.lambdas.landing_page_variant_handler.lambda_handler"

  memory_size           = 1024
  timeout               = 300
  environment_variables = local.lambda_environment_variables

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access
  ]

  tags = var.tags
}

module "persist_result_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "persist_result_lambda"
  description  = "LANDERAI generated result persistence Lambda."
  role_arn     = aws_iam_role.lambda_exec["persist_result_lambda"].arn

  source_file = "${path.root}/../../src/persist_result_lambda/handler.py"
  output_path = "${path.root}/build/persist_result_lambda.zip"
  handler     = "app.lambdas.persist_result_handler.lambda_handler"

  memory_size           = 512
  timeout               = 60
  environment_variables = local.lambda_environment_variables

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access
  ]

  tags = var.tags
}

module "revision_worker_lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  lambda_name  = "revision_worker_lambda"
  description  = "LANDERAI landing page revision SQS worker Lambda."
  role_arn     = aws_iam_role.lambda_exec["revision_worker_lambda"].arn

  source_file = "${path.root}/../../src/revision_worker_lambda/handler.py"
  output_path = "${path.root}/build/revision_worker_lambda.zip"
  handler     = "app.lambdas.revision_worker_handler.lambda_handler"

  memory_size                    = 1024
  timeout                        = 300
  reserved_concurrent_executions = 3
  environment_variables          = local.lambda_environment_variables

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access,
    aws_iam_role_policy_attachment.lambda_landing_page_s3_access,
    aws_iam_role_policy_attachment.lambda_ssm_parameter_access,
    aws_iam_role_policy_attachment.revision_worker_sqs_access,
  ]

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "revision_worker" {
  event_source_arn = module.revision_queue.queue_arn
  function_name    = module.revision_worker_lambda.function_arn
  batch_size       = 1
  enabled          = true

  depends_on = [
    aws_iam_role_policy_attachment.revision_worker_sqs_access,
  ]
}
