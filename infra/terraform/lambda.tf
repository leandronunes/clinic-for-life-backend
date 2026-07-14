data "archive_file" "video_compressor" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/video-compressor"
  output_path = "${path.module}/build/video-compressor.zip"
}

resource "aws_cloudwatch_log_group" "video_compressor" {
  name              = "/aws/lambda/video-compressor"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "video_compressor" {
  function_name    = "video-compressor"
  role             = aws_iam_role.video_compressor.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.video_compressor.output_path
  source_code_hash = data.archive_file.video_compressor.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  layers           = [aws_serverlessapplicationrepository_cloudformation_stack.ffmpeg_layer.outputs["LayerVersion"]]

  ephemeral_storage {
    size = var.lambda_ephemeral_storage_mb
  }

  environment {
    variables = {
      # ffmpeg-lambda-layer (see ffmpeg_layer.tf) exposes the binaries here.
      FFMPEG_PATH = "/opt/bin/ffmpeg"
    }
  }

  # Ensure our explicitly-retained log group exists before the function
  # does, so Lambda never auto-creates one with the default (never-expire)
  # retention first.
  depends_on = [aws_cloudwatch_log_group.video_compressor]
}
