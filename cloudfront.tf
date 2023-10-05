locals {
  s3_origin_id = "${local.service.cartographie_nationale.client.name}_s3"
}


data "terraform_remote_state" "api" {
  backend = "remote"

  config = {
    organization = "cartographie-nationale"
    workspaces = {
      name = "api-production"
    }
  }
}

data "aws_s3_bucket" "client" {
  bucket = replace("${local.product_information.context.project}_${local.service.cartographie_nationale.client.name}", "_", "-")
}

resource "aws_cloudfront_cache_policy" "api_cache_policy" {
  name        = "${local.product_information.context.project}-CachingWithQueryParams"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

data "aws_cloudfront_origin_request_policy" "api_cloudfront_origin_request_policy" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_identity" "client" {
  comment = "S3 cloudfront origin access identity for ${local.service.cartographie_nationale.client.title} service in ${local.projectTitle}"
}

resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name = "cartographie-nationale-security-headers-policy"

  custom_headers_config {
    items {
      header   = "permissions-policy"
      override = true
      value    = "accelerometer=(), camera=(), geolocation=(self), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"
    }
  }

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    strict_transport_security {
      access_control_max_age_sec = "63072000"
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_security_policy {
      content_security_policy = "default-src 'self' data: https://*.gouv.fr https://openmaptiles.github.io ; font-src 'self' https://cdn.jsdelivr.net; img-src 'self' data: https://*.gouv.fr; object-src 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.gouv.fr blob:; style-src 'self' 'unsafe-inline';"
      override                = true
    }
  }
}

resource "aws_cloudfront_distribution" "cartographie_nationale" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = local.domainNames

  custom_error_response {
    error_caching_min_ttl = 7200
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  # S3 Origin
  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.client.cloudfront_access_identity_path
    }

    domain_name = data.aws_s3_bucket.client.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  # API Gateway Origin
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    domain_name = data.terraform_remote_state.api.outputs.api_host_name
    origin_id   = "api"
  }

  # S3 by default
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 7200
    min_ttl                    = 0
    max_ttl                    = 86400
    target_origin_id           = local.s3_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # API for /api/* routes
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api"

    cache_policy_id          = aws_cloudfront_cache_policy.api_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.api_cloudfront_origin_request_policy.id
    viewer_protocol_policy   = "redirect-to-https"

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.remove_api_path_parameter.qualified_arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["FR", "GF", "PF", "TF", "GP", "MQ", "YT", "NC", "RE", "BL", "MF", "PM", "WF", "US", "ES", "DE", "IT"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.acm_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags
}

data "aws_iam_policy_document" "client_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.client.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.client.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.client.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.client.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "client" {
  bucket = data.aws_s3_bucket.client.id
  policy = data.aws_iam_policy_document.client_s3_policy.json
}
