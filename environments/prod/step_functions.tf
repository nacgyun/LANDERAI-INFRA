module "landing_page_workflow" {
  source = "../../modules/step_function"

  project_name  = var.project_name
  environment   = var.environment
  workflow_name = "landing-page-workflow"
  role_arn      = aws_iam_role.step_functions_exec.arn

  embedding_lambda_arn            = module.embedding_lambda.function_arn
  design_plan_lambda_arn          = module.design_plan_lambda.function_arn
  landing_page_variant_lambda_arn = module.landing_page_variant_lambda.function_arn
  persist_result_lambda_arn       = module.persist_result_lambda.function_arn

  depends_on = [
    aws_iam_role_policy_attachment.step_functions_lambda_invoke
  ]

  tags = var.tags
}
