################################################################################
# s3 - client
################################################################################

resource "aws_s3_bucket" "client" {
  bucket = "spa-client-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_website_configuration" "client" {
  bucket = aws_s3_bucket.client.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "client" {
  depends_on = [
    aws_s3_bucket_ownership_controls.client,
    aws_s3_bucket_public_access_block.client,
  ]

  bucket = aws_s3_bucket.client.id
  acl    = "public-read"
}

resource "aws_s3_bucket_ownership_controls" "client" {
  bucket = aws_s3_bucket.client.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "client" {
  bucket = aws_s3_bucket.client.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
    sid     = "PublicReadGetObject"
    actions = ["s3:GetObject"]
    effect  = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.client.arn,
      "${aws_s3_bucket.client.arn}/*"
    ]
  }

  statement {
    sid = "AllowObjectPut"
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"] // This allows anyone to add objects to your bucket and is not recommended. It is recommended that the user that provisions resources has permission to put objects inside account buckets.
    }
    resources = [
      aws_s3_bucket.client.arn,
      "${aws_s3_bucket.client.arn}/*"
    ]
  }
}

resource "aws_s3_object" "spa_files" {
  for_each     = fileset("${path.root}/../spa", "**")
  bucket       = aws_s3_bucket.client.id
  key          = each.value
  source       = "${path.root}/../spa/${each.value}"
  etag         = filemd5("${path.root}/../spa/${each.key}")
  content_type = "text/html"
}
