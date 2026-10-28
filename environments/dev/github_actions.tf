locals {
  github_actions_lambda_function_arns = [
    module.api_lambda.function_arn,
    module.embedding_lambda.function_arn,
    module.design_plan_lambda.function_arn,
    module.landing_page_variant_lambda.function_arn,
    module.persist_result_lambda.function_arn,
    module.revision_worker_lambda.function_arn,
  ]
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_actions_repository}:environment:${var.environment}",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_lambda_deploy" {
  name               = "${var.project_name}-${var.environment}-github-actions-lambda-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "github_actions_lambda_deploy" {
  statement {
    actions = [
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]

    resources = local.github_actions_lambda_function_arns
  }
}

resource "aws_iam_policy" "github_actions_lambda_deploy" {
  name   = "${var.project_name}-${var.environment}-github-actions-lambda-deploy"
  policy = data.aws_iam_policy_document.github_actions_lambda_deploy.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "github_actions_lambda_deploy" {
  role       = aws_iam_role.github_actions_lambda_deploy.name
  policy_arn = aws_iam_policy.github_actions_lambda_deploy.arn
}
