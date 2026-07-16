resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.video_compressor.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = data.aws_s3_bucket.app.arn
  source_account = data.aws_caller_identity.current.account_id
}

# IMPORTANT: aws_s3_bucket_notification manages the bucket's ENTIRE
# notification configuration, not just this one rule — applying this for
# the first time will silently remove any other manually-configured
# notification on the bucket. Before the first `terraform apply`, run
# `aws s3api get-bucket-notification-configuration --bucket <bucket>` and,
# if anything is already there, add it here as an additional
# `lambda_function`/`topic`/`queue` block. See docs/video-compression.md.
resource "aws_s3_bucket_notification" "app" {
  bucket = data.aws_s3_bucket.app.id

  # Production raw uploads.
  lambda_function {
    lambda_function_arn = aws_lambda_function.video_compressor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.raw_prefix
  }

  # Dev raw uploads (dev/uploads/raw/...) — same Lambda, separate trigger
  # since S3 notification filters can't match two disjoint prefixes in one
  # block. The Lambda's key rewrite only swaps the "uploads/raw/" segment
  # for "uploads/", so the leading "dev/" is preserved end to end: dev
  # videos land back under dev/uploads/, production ones under uploads/ —
  # the two never cross.
  lambda_function {
    lambda_function_arn = aws_lambda_function.video_compressor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.dev_raw_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
