resource "aws_route53_zone" "primary" {
  name    = var.root_domain_name
  comment = "Public DNS zone for ${var.root_domain_name}."

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    {
      ManagedBy = "Terraform"
      Project   = "landerai"
    },
    var.tags
  )
}
