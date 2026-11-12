data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "app_assets" {
  bucket        = "avora-app-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = true

  tags = {
    Name    = "avora-app-assets"
    Project = "avora"
  }
}

resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket                  = aws_s3_bucket.app_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "app_index" {
  bucket       = aws_s3_bucket.app_assets.id
  key          = "index.html"
  source       = "${path.module}/../app/index.html"
  etag         = filemd5("${path.module}/../app/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "app_css" {
  bucket       = aws_s3_bucket.app_assets.id
  key          = "styles.css"
  source       = "${path.module}/../app/styles.css"
  etag         = filemd5("${path.module}/../app/styles.css")
  content_type = "text/css"
}

resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.app_assets.id
  key          = "app.js"
  source       = "${path.module}/../app/app.js"
  etag         = filemd5("${path.module}/../app/app.js")
  content_type = "application/javascript"
}

resource "aws_iam_role_policy" "ec2_app_assets" {
  name = "avora-read-app-assets"
  role = aws_iam_role.ec2_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.app_assets.arn}/*"
    }]
  })
}
