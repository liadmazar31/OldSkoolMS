# S3 Bucket for tib-ms
resource "aws_s3_bucket" "tib_ms" {
  bucket = "tib-ms"

  tags = {
    Name        = "tib-ms"
    Environment = "production"
  }
}

# Block public access settings - allowing public access
resource "aws_s3_bucket_public_access_block" "tib_ms" {
  bucket = aws_s3_bucket.tib_ms.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket versioning (optional - enable if you want versioning)
resource "aws_s3_bucket_versioning" "tib_ms" {
  bucket = aws_s3_bucket.tib_ms.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public read policy - allows public read access
resource "aws_s3_bucket_policy" "tib_ms_public_read" {
  bucket = aws_s3_bucket.tib_ms.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.tib_ms.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.tib_ms]
}

# Website configuration (optional - uncomment if you want to host a static website)
# resource "aws_s3_bucket_website_configuration" "tib_ms" {
#   bucket = aws_s3_bucket.tib_ms.id
#
#   index_document {
#     suffix = "index.html"
#   }
#
#   error_document {
#     key = "error.html"
#   }
# }

# CORS configuration (optional - uncomment if you need CORS)
# resource "aws_s3_bucket_cors_configuration" "tib_ms" {
#   bucket = aws_s3_bucket.tib_ms.id
#
#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins = ["*"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# }

