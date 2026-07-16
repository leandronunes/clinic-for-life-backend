variable "aws_region" {
  description = "AWS region the S3 bucket and Lambda live in."
  type        = string
  default     = "us-west-2"
}

variable "s3_bucket_name" {
  description = "Existing, console-managed S3 bucket that stores uploads (not managed by Terraform)."
  type        = string
  default     = "clinic-for-life"
}

variable "raw_prefix" {
  description = "S3 key prefix for transient raw exercise-video uploads made in production, watched by the S3 event trigger."
  type        = string
  default     = "uploads/raw/"
}

variable "dev_raw_prefix" {
  description = "S3 key prefix for transient raw exercise-video uploads made from a local/dev environment (see S3Presigner#env_prefix), watched by a second S3 event trigger so dev uploads get compressed too, independently of and never mixed with production keys."
  type        = string
  default     = "dev/uploads/raw/"
}

variable "raw_upload_expiration_days" {
  description = "Days after which objects under raw_prefix are auto-deleted by an S3 lifecycle rule."
  type        = number
  default     = 1
}

variable "ffmpeg_sar_application_id" {
  description = <<-EOT
    AWS Serverless Application Repository ID for the ffmpeg Lambda layer —
    serverlesspub/ffmpeg-aws-lambda-layer (verified author Gojko Adzic,
    https://github.com/serverlesspub/ffmpeg-aws-lambda-layer), confirmed
    with the user before wiring in. Deploys a Lambda Layer providing
    ffmpeg/ffprobe at /opt/bin/ in our own account (not a shared
    cross-account ARN) — see ffmpeg_layer.tf.
  EOT
  type        = string
  default     = "arn:aws:serverlessrepo:us-east-1:145266761615:applications/ffmpeg-lambda-layer"
}

variable "ffmpeg_sar_semantic_version" {
  description = "Semantic version of the ffmpeg-lambda-layer SAR application to deploy."
  type        = string
  default     = "1.0.0"
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB — also determines the vCPU share available to ffmpeg."
  type        = number
  default     = 3008
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 300
}

variable "lambda_ephemeral_storage_mb" {
  description = "Lambda /tmp size in MB — must fit the raw download + ffmpeg output + working files."
  type        = number
  default     = 2048
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda's log group."
  type        = number
  default     = 14
}
