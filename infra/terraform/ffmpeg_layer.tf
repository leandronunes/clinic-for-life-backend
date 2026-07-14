# Deploys the ffmpeg-lambda-layer AWS Serverless Application Repository app
# (serverlesspub/ffmpeg-aws-lambda-layer, verified author Gojko Adzic) into
# our own account, producing a Lambda Layer with ffmpeg/ffprobe at
# /opt/bin/ — confirmed with the project owner before wiring this specific
# third-party source in. There is no shared cross-account ARN for this
# layer; deploying the SAR application is the maintainer's documented way
# to consume it.
resource "aws_serverlessapplicationrepository_cloudformation_stack" "ffmpeg_layer" {
  name             = "ffmpeg-lambda-layer"
  application_id   = var.ffmpeg_sar_application_id
  semantic_version = var.ffmpeg_sar_semantic_version
  capabilities     = []
}
