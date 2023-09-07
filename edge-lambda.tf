data "archive_file" "remove_api_path_parameter_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda@edge/remove-api-path-parameter"
  output_path = "${path.module}/lambda@edge/remove-api-path-parameter.zip"
}

resource "aws_lambda_function" "remove_api_path_parameter" {
  provider         = aws.us-east-1
  filename         = "lambda@edge/remove-api-path-parameter.zip"
  function_name    = "remove-api-path-parameter"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.remove_api_path_parameter_archive.output_base64sha256
}

data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role-for-remove-api-path-parameter"
  description        = "Authentication iam role references a policy document that can assume role for lambda@edge execution"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_lambda_permission" "cloudfront" {
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remove_api_path_parameter.function_name
  principal     = "edgelambda.amazonaws.com"

  source_arn = aws_cloudfront_distribution.cartographie_nationale.arn
}
