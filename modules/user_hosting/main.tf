data "aws_caller_identity" "current" {}

locals {
  not_found_html = templatefile("${path.module}/errors/404.html", {
    main_page_url = "https://${var.frontend_domain_name}/"
  })
  bucket_name = "${var.project_name}-${var.environment}-user-hosting-${data.aws_caller_identity.current.account_id}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_s3_bucket" "hosting" {
  bucket = local.bucket_name
  tags   = merge(local.common_tags, { Name = local.bucket_name })
}

resource "aws_s3_object" "not_found" {
  bucket        = aws_s3_bucket.hosting.id
  key           = "_hosting-errors/404.html"
  content       = local.not_found_html
  content_type  = "text/html; charset=utf-8"
  cache_control = "no-store, max-age=0"
  source_hash   = sha256(local.not_found_html)
}

resource "aws_s3_bucket_public_access_block" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "hosting" {
  name                              = "${var.project_name}-${var.environment}-user-hosting"
  description                       = "OAC for ${var.environment} user-hosted landing pages."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "host_router" {
  name    = "${var.project_name}-${var.environment}-user-host-router"
  runtime = "cloudfront-js-2.0"
  comment = "Routes each user site hostname to its published S3 prefix."
  publish = true
  code    = <<-JAVASCRIPT
    function handler(event) {
      var request = event.request;
      var host = request.headers.host.value.toLowerCase();
      var suffix = ".${var.base_domain}";

      if (host.length <= suffix.length || host.slice(-suffix.length) !== suffix) {
        return {
          statusCode: 400,
          statusDescription: "Bad Request"
        };
      }

      var slug = host.slice(0, -suffix.length);
      if (!/^[a-z0-9](?:[a-z0-9-]{0,48}[a-z0-9])?$/.test(slug)) {
        return {
          statusCode: 404,
          statusDescription: "Not Found",
          headers: {
            "content-type": { value: "text/html; charset=utf-8" },
            "cache-control": { value: "no-store" }
          },
          body: request.method === "HEAD" ? "" : ${jsonencode(local.not_found_html)}
        };
      }

      var uri = request.uri || "/";
      if (uri === "/") {
        uri = "/index.html";
      } else if (uri.slice(-1) === "/") {
        uri += "index.html";
      }

      request.uri = "/published/" + slug + uri;
      return request;
    }
  JAVASCRIPT
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.project_name}-${var.environment}-user-hosting-security"
  comment = "Security headers for user-hosted landing pages."

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = false
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "hosting" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_200"
  comment         = "${var.project_name}-${var.environment} user hosting"
  aliases         = ["*.${var.base_domain}"]

  origin {
    domain_name              = aws_s3_bucket.hosting.bucket_regional_domain_name
    origin_id                = "user-hosting-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.hosting.id
  }

  default_cache_behavior {
    target_origin_id       = "user-hosting-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS managed CachingDisabled. Publishing to a stable URL is visible immediately.
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.host_router.arn
    }
  }

  origin {
    domain_name              = aws_s3_bucket.errors.bucket_regional_domain_name
    origin_id                = "hosting-error-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.hosting.id
  }

  dynamic "custom_error_response" {
    for_each = toset([500, 502, 503, 504])
    content {
      error_code            = custom_error_response.value
      response_code         = 503
      response_page_path    = "/${aws_s3_object.unavailable.key}"
      error_caching_min_ttl = 0
    }
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 0
  }

  ordered_cache_behavior {
    path_pattern               = "/_hosting-errors/503.html"
    target_origin_id           = "hosting-error-s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  # Error documents must bypass the per-site URI rewrite.
  ordered_cache_behavior {
    path_pattern               = "/_hosting-errors/*"
    target_origin_id           = "user-hosting-s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${aws_s3_object.not_found.key}"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "hosting" {
  statement {
    sid       = "AllowCloudFrontToIdentifyMissingObjects"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.hosting.arn]

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

  statement {
    sid     = "AllowCloudFrontReadPublishedObjects"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.hosting.arn}/published/*",
      "${aws_s3_bucket.hosting.arn}/_hosting-errors/404.html",
    ]

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

resource "aws_s3_bucket_policy" "hosting" {
  bucket = aws_s3_bucket.hosting.id
  policy = data.aws_iam_policy_document.hosting.json

  depends_on = [aws_s3_bucket_public_access_block.hosting]
}
