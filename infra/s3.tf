resource "aws_s3_bucket" "serverless_libreoffice_pdf" {
  bucket = "serverless-libreoffice-pdf"
  acl    = "public-read"

  lifecycle_rule {
    id      = "tmp"
    prefix  = "tmp/"
    enabled = true

    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = "${aws_s3_bucket.serverless_libreoffice_pdf.id}"
  policy = "${data.aws_iam_policy_document.allow_public_read.json}"
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "*",
      ]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.serverless_libreoffice_pdf.arn}/tmp/*",
    ]
  }
}
