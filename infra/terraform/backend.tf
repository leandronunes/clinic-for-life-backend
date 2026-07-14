# Remote state in a small, dedicated S3 bucket — created once, manually,
# before the first `terraform init` (Terraform can't create the bucket that
# stores its own state). See docs/video-compression.md for the one-time
# bootstrap commands (bucket + versioning + encryption + public-access
# block). Uses Terraform's native S3 locking (`use_lockfile`, >= 1.10) —
# no DynamoDB table needed.
terraform {
  backend "s3" {
    bucket       = "clinic-for-life-terraform-state"
    key          = "video-compression/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
