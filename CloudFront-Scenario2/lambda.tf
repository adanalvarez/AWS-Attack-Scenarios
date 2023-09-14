resource "aws_iam_role" "cookies_lambda_role" {
  name = "cookies_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "Service" : [
            "edgelambda.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_logs" {
  name        = "LambdaLogs"
  description = "Allows Lambda function to write logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.cookies_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}


data "archive_file" "cookies_lambda_zip" {
  type        = "zip"
  source_file = "parseCookie.py"
  output_path = "parseCookie.zip"
}

resource "aws_lambda_function" "cookies_lambda" {
  filename      = data.archive_file.cookies_lambda_zip.output_path
  function_name = "parseCookie"
  role          = aws_iam_role.cookies_lambda_role.arn
  handler       = "parseCookie.lambda_handler"

  source_code_hash = data.archive_file.cookies_lambda_zip.output_base64sha256

  runtime = "python3.8"

  publish = true
}

resource "aws_lambda_function_event_invoke_config" "cookies_lambda_config" {
  function_name                = aws_lambda_function.cookies_lambda.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 60
}

resource "aws_lambda_alias" "cookies_lambda_alias" {
  name             = "latest"
  function_name    = aws_lambda_function.cookies_lambda.function_name
  function_version = "$LATEST"
}