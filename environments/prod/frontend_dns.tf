data "aws_route53_zone" "primary" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_acm_certificate" "frontend" {
  provider          = aws.us_east_1
  domain_name       = var.frontend_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_route53_record" "frontend_certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.frontend.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_certificate_validation : record.fqdn]
}

resource "aws_route53_record" "frontend_ipv4" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.frontend_domain_name
  type    = "A"

  alias {
    name                   = module.frontend_hosting.distribution_domain_name
    zone_id                = module.frontend_hosting.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_ipv6" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.frontend_domain_name
  type    = "AAAA"

  alias {
    name                   = module.frontend_hosting.distribution_domain_name
    zone_id                = module.frontend_hosting.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
