resource "aws_sns_topic" "prod_alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = var.tags
}
