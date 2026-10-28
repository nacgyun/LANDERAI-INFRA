resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "landerai-prod-dashbaoard"

  dashboard_body = jsonencode(
    jsondecode(
      file("${path.module}/dashboards/overview.json")
    )
  )
}
