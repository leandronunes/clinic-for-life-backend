data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "video_compressor" {
  name               = "video-compressor-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.video_compressor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Scoped tightly: read only the transient raw/ prefixes (production and
# dev), write only under the matching final uploads/ prefix (the key the
# Lambda writes the compressed result to) — dev and production stay in
# their own namespaces.
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid     = "ReadRaw"
    actions = ["s3:GetObject"]
    resources = [
      "${data.aws_s3_bucket.app.arn}/${var.raw_prefix}*",
      "${data.aws_s3_bucket.app.arn}/${var.dev_raw_prefix}*",
    ]
  }

  statement {
    sid     = "WriteFinal"
    actions = ["s3:PutObject"]
    resources = [
      "${data.aws_s3_bucket.app.arn}/uploads/*",
      "${data.aws_s3_bucket.app.arn}/dev/uploads/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  role   = aws_iam_role.video_compressor.id
  policy = data.aws_iam_policy_document.s3_access.json
}
