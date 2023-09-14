resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Origin Access Identity for Content Bucket"
}

resource "aws_cloudfront_distribution" "content_distribution" {
  origin {
    domain_name = aws_s3_bucket.content_bucket.bucket_regional_domain_name
    origin_id   = "ContentS3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for Content Bucket"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ContentS3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    path_pattern           = "/login.html"
    smooth_streaming       = false
    target_origin_id       = "ContentS3Origin"
    trusted_key_groups     = []
    trusted_signers        = []
    viewer_protocol_policy = "allow-all"

  }

  ordered_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    path_pattern           = "/*"
    smooth_streaming       = false
    target_origin_id       = "ContentS3Origin"
    trusted_key_groups     = []
    trusted_signers        = []
    viewer_protocol_policy = "allow-all"

    lambda_function_association {
      event_type   = "viewer-request"
      include_body = false
      lambda_arn   = "${aws_lambda_function.cookies_lambda.arn}:${aws_lambda_function.cookies_lambda.version}"
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_url" {
  description = "The URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.content_distribution.domain_name}/"
}