locals {
  table_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_dynamodb_table" "core" {
  name         = "${local.table_prefix}-coreTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "landing_request" {
  name         = "${local.table_prefix}-LandingRequest"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIdCreatedAtIndex"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "project_id",
      "industry",
      "sub_industry",
      "target",
      "style",
      "goal",
      "status",
      "current_step",
      "progress",
      "selection_status",
      "chosen_variant",
      "updated_at",
    ]
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "landing_result" {
  name         = "${local.table_prefix}-LandingResult"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "result_id"

  attribute {
    name = "result_id"
    type = "S"
  }

  attribute {
    name = "request_id"
    type = "S"
  }

  global_secondary_index {
    name            = "RequestIdIndex"
    hash_key        = "request_id"
    projection_type = "ALL"
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "rag_design_plan" {
  name         = "${local.table_prefix}-RAG_DESIGNPLAN"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "design_plan_id"

  attribute {
    name = "design_plan_id"
    type = "S"
  }

  attribute {
    name = "request_id"
    type = "S"
  }

  global_secondary_index {
    name            = "RequestIdIndex"
    hash_key        = "request_id"
    projection_type = "ALL"
  }

  tags = local.common_tags
}
