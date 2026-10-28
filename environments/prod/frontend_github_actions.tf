data "aws_iam_policy_document" "github_actions_frontend_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
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
        "repo:${var.github_actions_frontend_subject_repository}:environment:${var.environment}",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_frontend_deploy" {
  name               = "${var.project_name}-${var.environment}-github-actions-frontend-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_frontend_assume_role.json

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "github_actions_frontend_deploy" {
  statement {
    sid = "ListFrontendBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [module.frontend_hosting.bucket_arn]
  }

  statement {
    sid = "DeployFrontendObjects"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${module.frontend_hosting.bucket_arn}/*"]
  }

  statement {
    sid       = "InvalidateFrontendCache"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [module.frontend_hosting.distribution_arn]
  }
}

resource "aws_iam_role_policy" "github_actions_frontend_deploy" {
  name   = "${var.project_name}-${var.environment}-frontend-deploy"
  role   = aws_iam_role.github_actions_frontend_deploy.id
  policy = data.aws_iam_policy_document.github_actions_frontend_deploy.json
}
