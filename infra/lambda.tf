resource "aws_lambda_function" "convert" {
  function_name    = "${var.env}_${var.fn_name}"
  handler          = "handler.handler"
  runtime          = "nodejs6.10"
  role             = "${aws_iam_role.convert.arn}"
  s3_bucket        = "${aws_s3_bucket.serverless_libreoffice_pdf.id}"
  s3_key           = "${aws_s3_bucket_object.package.key}"
  memory_size      = 1536
  timeout          = 25
  source_code_hash = "${base64sha256(file(data.archive_file.convert.output_path))}"

  tracing_config {
    mode = "Active"
  }

  environment {
    variables {
      S3_BUCKET_NAME = "${aws_s3_bucket.serverless_libreoffice_pdf.id}"
    }
  }
}

data "archive_file" "convert" {
  type        = "zip"
  output_path = "./${var.fn_name}.zip"
  source_dir  = "../../../src/libreoffice"
}

resource "aws_s3_bucket_object" "package" {
  bucket = "${aws_s3_bucket.serverless_libreoffice_pdf.id}"
  key    = "package.zip"
  source = "${data.archive_file.convert.output_path}"
  etag   = "${md5(file(data.archive_file.convert.output_path))}"
}

resource "aws_cloudwatch_log_group" "convert" {
  name = "/aws/lambda/${aws_lambda_function.convert.id}"
}
