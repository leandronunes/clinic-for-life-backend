# IMPORTANT: same "manages the whole config" caveat as
# aws_s3_bucket_notification — this resource is authoritative over the
# bucket's ENTIRE lifecycle configuration. Snapshot with
# `aws s3api get-bucket-lifecycle-configuration --bucket <bucket>` before
# the first apply and fold in any existing rules as additional `rule`
# blocks. See docs/video-compression.md.
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = data.aws_s3_bucket.app.id

  rule {
    id     = "expire-raw-uploads"
    status = "Enabled"

    filter {
      prefix = var.raw_prefix
    }

    expiration {
      days = var.raw_upload_expiration_days
    }
  }
}
