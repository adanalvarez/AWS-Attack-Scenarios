resource "random_pet" "bucket_name" {
  length    = 2
  separator = "-"
}

resource "aws_s3_bucket" "content_bucket" {
  bucket = "content-s3-${random_pet.bucket_name.id}-bucket"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://*.cloudfront.net"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false

      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid       = "AllowCloudFrontAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.content_bucket.arn}/*"]

    principals {
      identifiers = ["${aws_cloudfront_origin_access_identity.oai.iam_arn}"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.content_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.content_bucket.id
  key          = "index.html"
  source       = "index.html"
  etag         = filemd5("index.html")
  content_type = "text/html"

}

resource "aws_s3_object" "login" {
  bucket       = aws_s3_bucket.content_bucket.id
  key          = "login.html"
  source       = "login.html"
  etag         = filemd5("login.html")
  content_type = "text/html"
}