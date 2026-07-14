# The app's S3 bucket is created/console-managed outside Terraform — we
# only reference it here (via a data source), never as a managed resource,
# so `terraform apply` can never attempt to recreate or delete it.
data "aws_s3_bucket" "app" {
  bucket = var.s3_bucket_name
}

data "aws_caller_identity" "current" {}
