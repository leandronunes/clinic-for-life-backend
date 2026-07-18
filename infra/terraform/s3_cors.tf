# IMPORTANT: same "manages the whole config" caveat as
# aws_s3_bucket_notification / aws_s3_bucket_lifecycle_configuration — this
# resource is authoritative over the bucket's ENTIRE CORS configuration.
# Snapshotted via `aws s3api get-bucket-cors --bucket <bucket>` before the
# first apply; every origin below already existed except
# https://app.nucleoforlife.com.br, added so direct browser→S3 presigned
# uploads (see app/lib/s3_presigner.rb) work from the new frontend domain.
# See docs/video-compression.md for the general caveat.
resource "aws_s3_bucket_cors_configuration" "app" {
  bucket = data.aws_s3_bucket.app.id

  cors_rule {
    allowed_headers = ["Content-Type"]
    allowed_methods = ["PUT"]
    allowed_origins = [
      "http://localhost:3000",
      "http://localhost:5173",
      "http://localhost:4173",
      "https://nucleoforlife.com.br",
      "https://api.nucleoforlife.com.br",
      "https://app.nucleoforlife.com.br",
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
