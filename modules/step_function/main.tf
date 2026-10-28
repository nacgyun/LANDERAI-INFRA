locals {
  state_machine_name = "${var.project_name}-${var.environment}-${var.workflow_name}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_sfn_state_machine" "this" {
  name     = local.state_machine_name
  role_arn = var.role_arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "LANDERAI landing page generation workflow"
    StartAt = "CreateRequestEmbedding"
    States = {
      CreateRequestEmbedding = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.embedding_lambda_arn
          "Payload.$"  = "$"
        }
        OutputPath = "$.Payload"
        Retry      = local.lambda_retry
        Catch      = [local.workflow_catch]
        Next       = "CreateDesignPlan"
      }

      CreateDesignPlan = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.design_plan_lambda_arn
          "Payload.$"  = "$"
        }
        OutputPath = "$.Payload"
        Retry      = local.lambda_retry
        Catch      = [local.workflow_catch]
        Next       = "GenerateLandingPageVariants"
      }

      GenerateLandingPageVariants = {
        Type           = "Map"
        ItemsPath      = "$.variants"
        MaxConcurrency = var.variant_max_concurrency
        Parameters = {
          "request_id.$"       = "$.request_id"
          "variant.$"          = "$$.Map.Item.Value"
          "design_plan_json.$" = "$.design_plan_json"
        }
        ResultPath = "$.generated_variants"
        Iterator = {
          StartAt = "GenerateLandingPageVariant"
          States = {
            GenerateLandingPageVariant = {
              Type     = "Task"
              Resource = "arn:aws:states:::lambda:invoke"
              Parameters = {
                FunctionName = var.landing_page_variant_lambda_arn
                "Payload.$"  = "$"
              }
              OutputPath = "$.Payload"
              Retry      = local.lambda_retry
              End        = true
            }
          }
        }
        Catch = [local.workflow_catch]
        Next  = "PersistResult"
      }

      PersistResult = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.persist_result_lambda_arn
          Payload = {
            "request_id.$"         = "$.request_id"
            "generated_variants.$" = "$.generated_variants"
          }
        }
        OutputPath = "$.Payload"
        Retry      = local.lambda_retry
        Catch      = [local.workflow_catch]
        End        = true
      }

      WorkflowFailed = {
        Type = "Fail"
      }
    }
  })

  tags = local.common_tags
}

locals {
  lambda_retry = [
    {
      ErrorEquals = [
        "Lambda.ServiceException",
        "Lambda.AWSLambdaException",
        "Lambda.SdkClientException",
      ]
      IntervalSeconds = 2
      MaxAttempts     = 3
      BackoffRate     = 2
    }
  ]

  workflow_catch = {
    ErrorEquals = ["States.ALL"]
    ResultPath  = "$.error"
    Next        = "WorkflowFailed"
  }
}
