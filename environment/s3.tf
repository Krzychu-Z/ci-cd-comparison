resource "aws_s3_bucket" "result_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "allow_access_for_tf_role" {
  bucket = aws_s3_bucket.result_bucket.id
  policy = data.aws_iam_policy_document.allow_access_for_tf_role.json
}

data "aws_iam_policy_document" "allow_access_for_tf_role" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.aws_role_arn]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.result_bucket.arn,
      "${aws_s3_bucket.result_bucket.arn}/*",
    ]
  }
}