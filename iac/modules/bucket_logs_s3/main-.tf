resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.id

  target_bucket = var.log_bucket_acces
  target_prefix = "/bucket_logs_s3/${var.bucket_name}"
}


resource "aws_s3_bucket_lifecycle_configuration" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.id

    rule {
    id      = "expire"
    status  = "Enabled"

    filter {
      
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.id

  block_public_acls = true
  block_public_policy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:Kms"
    }
  }
}

resource "aws_s3_bucket_notification" "this" {
  region = var.region
  bucket = aws_s3_bucket.this.id
    topic {
    topic_arn     = aws_sns_topic.bucket_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }
}