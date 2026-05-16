# --- Archives ---

data "archive_file" "fintech_post_confirmation_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/fintech-post-confirmation"
  output_path = "${path.root}/.terraform/archives/fintech_post_confirmation.zip"
}

data "archive_file" "fintech_get_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/fintech-get"
  output_path = "${path.root}/.terraform/archives/fintech_get.zip"
}

# --- Lambda functions ---

resource "aws_lambda_function" "fintech_post_confirmation" {
  function_name    = "cloud-presti-fintech-post-confirmation"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.fintech_post_confirmation_zip.output_path
  source_code_hash = data.archive_file.fintech_post_confirmation_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_FINTECH_TABLE = module.dynamodb_fintech.dynamodb_table_id
    }
  }
}

resource "aws_lambda_function" "fintech_get" {
  function_name    = "cloud-presti-fintech-get"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.fintech_get_zip.output_path
  source_code_hash = data.archive_file.fintech_get_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_FINTECH_TABLE = module.dynamodb_fintech.dynamodb_table_id
    }
  }
}

# --- Lambda permissions ---

resource "aws_lambda_permission" "cognito_fintech" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fintech_post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_permission" "api_gw_fintech_get" {
  statement_id  = "AllowExecutionFromAPIGatewayFintechGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fintech_get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

# --- Integration ---

resource "aws_apigatewayv2_integration" "fintech_get" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.fintech_get.invoke_arn
  payload_format_version = "2.0"
}

# --- Route ---

resource "aws_apigatewayv2_route" "get_fintech" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "GET /fintech"
  target             = "integrations/${aws_apigatewayv2_integration.fintech_get.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}
