################################################################################
# OIDC - IAM Deployment Role
################################################################################

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "deploy_s3_client_objects_role" {
  name               = "spa-s3-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.deployment_role_assume_role_policy.json
}

data "aws_iam_policy_document" "deployment_role_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test = "ForAnyValue:StringLike"
      values = [
        "repo:casstait/cloudfront-spa-infra:ref:refs/heads/main",
        "repo:casstait/cloudfront-spa-infra:environment:dev"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role_policy" "deploy_s3_client_objects" {
  name = "spa-s3-deploy-role-policy"
  role = aws_iam_role.deploy_s3_client_objects_role.name

  policy = data.aws_iam_policy_document.deployment_role_s3_policy.json
}

data "aws_iam_policy_document" "deployment_role_s3_policy" {
  statement {
    sid    = "ObjectWriteAccessClientS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjects",
    ]
    resources = ["${aws_s3_bucket.client.arn}/*"]
  }

  statement {
    sid       = "ListObjectsAccessClientS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.client.arn]
  }
}
