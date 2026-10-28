output "lambda_functions" {
  description = "Created Lambda functions."
  value = {
    api_lambda = {
      function_name  = module.api_lambda.function_name
      function_arn   = module.api_lambda.function_arn
      log_group_name = module.api_lambda.log_group_name
    }
    embedding_lambda = {
      function_name  = module.embedding_lambda.function_name
      function_arn   = module.embedding_lambda.function_arn
      log_group_name = module.embedding_lambda.log_group_name
    }
    design_plan_lambda = {
      function_name  = module.design_plan_lambda.function_name
      function_arn   = module.design_plan_lambda.function_arn
      log_group_name = module.design_plan_lambda.log_group_name
    }
    landing_page_variant_lambda = {
      function_name  = module.landing_page_variant_lambda.function_name
      function_arn   = module.landing_page_variant_lambda.function_arn
      log_group_name = module.landing_page_variant_lambda.log_group_name
    }
    persist_result_lambda = {
      function_name  = module.persist_result_lambda.function_name
      function_arn   = module.persist_result_lambda.function_arn
      log_group_name = module.persist_result_lambda.log_group_name
    }
    revision_worker_lambda = {
      function_name  = module.revision_worker_lambda.function_name
      function_arn   = module.revision_worker_lambda.function_arn
      log_group_name = module.revision_worker_lambda.log_group_name
    }
  }
}

output "revision_queue" {
  description = "Landing page revision queue and dead-letter queue."
  value = {
    queue_name = module.revision_queue.queue_name
    queue_url  = module.revision_queue.queue_url
    queue_arn  = module.revision_queue.queue_arn
    dlq_name   = module.revision_queue.dlq_name
    dlq_url    = module.revision_queue.dlq_url
    dlq_arn    = module.revision_queue.dlq_arn
  }
}

output "dynamodb_tables" {
  description = "Created DynamoDB tables."
  value       = module.dynamodb.table_names
}

output "landing_page_html_bucket" {
  description = "S3 bucket used to store generated landing page HTML."
  value       = aws_s3_bucket.landing_page_html.bucket
}

output "landing_page_workflow" {
  description = "Landing page Step Functions workflow."
  value = {
    state_machine_name = module.landing_page_workflow.state_machine_name
    state_machine_arn  = module.landing_page_workflow.state_machine_arn
  }
}

output "api_gateway" {
  description = "API Gateway endpoint for the API Lambda."
  value = {
    api_id   = module.api_gateway.api_id
    endpoint = module.api_gateway.api_endpoint
  }
}

output "github_actions_lambda_deploy_role_arn" {
  description = "IAM role ARN for the BE GitHub Actions Lambda deployment workflow."
  value       = aws_iam_role.github_actions_lambda_deploy.arn
}

output "frontend_hosting" {
  description = "Frontend S3 and CloudFront deployment details."
  value = {
    bucket_name              = module.frontend_hosting.bucket_name
    distribution_id          = module.frontend_hosting.distribution_id
    distribution_domain_name = module.frontend_hosting.distribution_domain_name
    url                      = module.frontend_hosting.url
  }
}

output "user_hosting" {
  description = "User-hosted landing page infrastructure."
  value = {
    bucket_name              = module.user_hosting.bucket_name
    distribution_id          = module.user_hosting.distribution_id
    distribution_domain_name = module.user_hosting.distribution_domain_name
    wildcard_domain          = "*.${var.user_hosting_base_domain}"
  }
}

output "github_actions_frontend_deploy_role_arn" {
  description = "IAM role ARN for the FE GitHub Actions S3 and CloudFront deployment workflow."
  value       = aws_iam_role.github_actions_frontend_deploy.arn
}
