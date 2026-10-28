resource "aws_route53_record" "clerk_frontend_api" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "clerk.${var.frontend_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["frontend-api.clerk.services"]
}

resource "aws_route53_record" "clerk_accounts" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "accounts.${var.frontend_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["accounts.clerk.services"]
}

resource "aws_route53_record" "clerk_email" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "clkmail.${var.frontend_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["mail.8osgq0b15vvh.clerk.services"]
}

resource "aws_route53_record" "clerk_email_dkim_primary" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "clk._domainkey.${var.frontend_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim1.8osgq0b15vvh.clerk.services"]
}

resource "aws_route53_record" "clerk_email_dkim_secondary" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "clk2._domainkey.${var.frontend_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim2.8osgq0b15vvh.clerk.services"]
}
