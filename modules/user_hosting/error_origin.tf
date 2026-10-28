# Separate bucket so a hosting-bucket policy issue does not hide the outage page.
resource "aws_s3_bucket" "errors" {
  bucket = "${var.project_name}-${var.environment}-hosting-errors-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "errors" {
  bucket                  = aws_s3_bucket.errors.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "errors" {
  bucket = aws_s3_bucket.errors.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  unavailable_html = templatefile("${path.module}/errors/503.html", {
    main_page_url = "https://${var.frontend_domain_name}/"
  })
}

resource "aws_s3_object" "unavailable" {
  bucket        = aws_s3_bucket.errors.id
  key           = "_hosting-errors/503.html"
  content       = local.unavailable_html
  content_type  = "text/html; charset=utf-8"
  cache_control = "no-store, max-age=0"
  source_hash   = sha256(local.unavailable_html)
}

data "aws_iam_policy_document" "errors" {
  statement {
    actions   = ["s3:GetObject"]
    resources = [aws_s3_object.unavailable.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.hosting.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "errors" {
  bucket     = aws_s3_bucket.errors.id
  policy     = data.aws_iam_policy_document.errors.json
  depends_on = [aws_s3_bucket_public_access_block.errors]
}
