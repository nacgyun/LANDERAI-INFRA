output "table_names" {
  description = "DynamoDB table names."
  value = {
    core_table      = aws_dynamodb_table.core.name
    landing_request = aws_dynamodb_table.landing_request.name
    landing_result  = aws_dynamodb_table.landing_result.name
    rag_design_plan = aws_dynamodb_table.rag_design_plan.name
  }
}

output "table_arns" {
  description = "DynamoDB table ARNs."
  value = {
    core_table      = aws_dynamodb_table.core.arn
    landing_request = aws_dynamodb_table.landing_request.arn
    landing_result  = aws_dynamodb_table.landing_result.arn
    rag_design_plan = aws_dynamodb_table.rag_design_plan.arn
  }
}

output "index_arns" {
  description = "DynamoDB secondary index ARNs."
  value = [
    "${aws_dynamodb_table.landing_request.arn}/index/UserIdCreatedAtIndex",
    "${aws_dynamodb_table.landing_result.arn}/index/RequestIdIndex",
    "${aws_dynamodb_table.rag_design_plan.arn}/index/RequestIdIndex"
  ]
}
