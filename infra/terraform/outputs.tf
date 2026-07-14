output "lambda_function_name" {
  value = aws_lambda_function.video_compressor.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.video_compressor.arn
}

output "iam_role_arn" {
  value = aws_iam_role.video_compressor.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.video_compressor.name
}
