################################################################################
# s3 - client
################################################################################

resource "aws_s3_bucket" "client" {
  bucket = "spa-client-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "client" {
  bucket = aws_s3_bucket.client.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "client" {
  bucket = aws_s3_bucket.client.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "client" {
  bucket = aws_s3_bucket.client.id
  versioning_configuration {
    status = var.bucket_versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "client" {
  bucket = aws_s3_bucket.client.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "client" {
  bucket = aws_s3_bucket.client.id

  rule {
    id     = "abort-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}

resource "aws_s3_bucket_policy" "client" {
  bucket = aws_s3_bucket.client.id
  policy = data.aws_iam_policy_document.client.json
}

data "aws_iam_policy_document" "client" {
  statement {
    sid     = "Deny requests that aren't using SSL/TLS"
    actions = ["s3:*"]
    effect  = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.client.arn,
      "${aws_s3_bucket.client.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }

  statement {
    sid     = "Grant a CloudFront Origin Access Control private access to S3 Bucket content"
    actions = ["s3:GetObject"]
    effect  = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    resources = ["${aws_s3_bucket.client.arn}/*"]
    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.this.arn]
      variable = "AWS:SourceArn"
    }
  }

  statement {
    sid     = "Grant a CloudFront Origin Access Control private access to S3 Bucket"
    actions = ["s3:ListBucket"]
    effect  = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    resources = [aws_s3_bucket.client.arn]
    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.this.arn]
      variable = "AWS:SourceArn"
    }
  }
}

################################################################################
# s3 - spa files
################################################################################

resource "aws_s3_object" "spa_files" {
  for_each = fileset("${path.root}/../spa", "**")
  bucket   = aws_s3_bucket.client.id
  key      = each.key
  source   = "${path.root}/../spa/${each.key}"
  etag     = filemd5("${path.root}/../spa/${each.key}")
}

################################################################################
# s3 - logs
################################################################################

resource "aws_s3_bucket" "logs" {
  bucket = "cdn-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = var.bucket_versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "abort-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }

  rule {
    id     = "infrequent-access-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      storage_class = "STANDARD_IA"
      days          = 95 # ~3 months
    }

    transition {
      storage_class = "GLACIER"
      days          = 185 # ~6 months
    }

    noncurrent_version_transition {
      storage_class   = "STANDARD_IA"
      noncurrent_days = 35 # ~1 month
    }

    noncurrent_version_transition {
      storage_class   = "GLACIER"
      noncurrent_days = 65 # ~2 months
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}

data "aws_iam_policy_document" "logs" {
  statement {
    sid     = "Deny requests that aren't using SSL/TLS"
    actions = ["s3:*"]
    effect  = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }

  statement {
    sid     = "AllowS3ServerLogs"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    resources = [
      "${aws_s3_bucket.logs.arn}/s3/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
  }

  statement {
    sid     = "AllowCloudfront"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "${aws_s3_bucket.logs.arn}/cloudfront/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.this.arn]
      variable = "AWS:SourceArn"
    }
  }
}
