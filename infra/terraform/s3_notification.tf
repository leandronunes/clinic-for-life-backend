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

  lambda_function {
    lambda_function_arn = aws_lambda_function.video_compressor.arn
    events              = ["s3:ObjectCreated:*"]

    # Production keys only, by design — a dev/ prefixed key from local
    # development against the same bucket does NOT match this and is
    # intentionally never auto-compressed.
    filter_prefix = var.raw_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
