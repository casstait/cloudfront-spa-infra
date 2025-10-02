################################################################################
# Cloudfront
################################################################################

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "cdn-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "this" {
  # Ensure certificate is validated before trying to provision this distribution
  depends_on = [aws_acm_certificate_validation.cloudfront]

  name = "cdn-caching-optimized-policy"

  # The following settings are based on the Managed-CachingOptimized settings - https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-caching-optimized
  min_ttl     = 1        # second
  max_ttl     = 31536000 # 365 days
  default_ttl = 86400    # 24 hours

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "this" {
  name = "cdn-origin-request-policy"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "CDN for the single page aplication"
  default_root_object = "index.html"

  is_ipv6_enabled = true

  web_acl_id = aws_wafv2_web_acl.this.arn
  aliases    = [var.domain]

  origin {
    domain_name              = aws_s3_bucket.client.bucket_regional_domain_name
    origin_id                = "default"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "default"
    allowed_methods        = ["HEAD", "GET", "OPTIONS"]
    cached_methods         = ["HEAD", "GET"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = aws_cloudfront_cache_policy.this.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.this.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket          = "${aws_s3_bucket.logs.id}.s3.amazonaws.com"
    prefix          = "cloudfront-s3-cdn/spa-client/${var.environment}/"
    include_cookies = false
  }

  viewer_certificate {
    ssl_support_method       = "sni-only"
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    minimum_protocol_version = "TLSv1.2_2018"
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response[*]
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }
}
