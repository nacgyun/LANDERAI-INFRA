resource "aws_acm_certificate" "user_hosting" {
  provider          = aws.us_east_1
  domain_name       = "*.${var.user_hosting_base_domain}"
  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

resource "aws_acm_certificate_validation" "user_hosting" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.user_hosting.arn
  # ACM gives a base domain and its wildcard the same DNS validation token.
  # Reuse the frontend certificate's CNAME instead of owning it twice.
  validation_record_fqdns = [for record in aws_route53_record.frontend_certificate_validation : record.fqdn]
}

module "user_hosting" {
  source               = "../../modules/user_hosting"
  project_name         = var.project_name
  environment          = var.environment
  base_domain          = var.user_hosting_base_domain
  frontend_domain_name = var.frontend_domain_name
  acm_certificate_arn  = aws_acm_certificate_validation.user_hosting.certificate_arn
  tags                 = var.tags
}

resource "aws_route53_record" "user_hosting_ipv4" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "*.${var.user_hosting_base_domain}"
  type    = "A"
  alias {
    name                   = module.user_hosting.distribution_domain_name
    zone_id                = module.user_hosting.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "user_hosting_ipv6" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "*.${var.user_hosting_base_domain}"
  type    = "AAAA"
  alias {
    name                   = module.user_hosting.distribution_domain_name
    zone_id                = module.user_hosting.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
