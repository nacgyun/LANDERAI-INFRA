output "hosted_zone_id" {
  description = "Route 53 public hosted zone ID."
  value       = aws_route53_zone.primary.zone_id
}

output "name_servers" {
  description = "Name servers that must be configured on the registered domain."
  value       = aws_route53_zone.primary.name_servers
}
