module "frontend_hosting" {
  source = "../../modules/frontend_hosting"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
  aliases      = [var.frontend_domain_name]

  acm_certificate_arn = aws_acm_certificate_validation.frontend.certificate_arn
}
