# --- Archives ---

data "archive_file" "product_get_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/product-get"
  output_path = "${path.root}/.terraform/archives/product_get.zip"
}

data "archive_file" "product_create_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/product-create"
  output_path = "${path.root}/.terraform/archives/product_create.zip"
}

data "archive_file" "product_update_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/product-update"
  output_path = "${path.root}/.terraform/archives/product_update.zip"
}

data "archive_file" "product_delete_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/product-delete"
  output_path = "${path.root}/.terraform/archives/product_delete.zip"
}

# --- Lambda functions ---

resource "aws_lambda_function" "product_get" {
  function_name    = "cloud-presti-product-get"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.product_get_zip.output_path
  source_code_hash = data.archive_file.product_get_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids = [
      module.vpc.subnet_ids["10.0.2.0/24"],
      module.vpc.subnet_ids["10.0.5.0/24"],
    ]
    security_group_ids = [module.vpc.security_group_ids["lambda-sg"]]
  }

  environment {
    variables = {
      DYNAMODB_PRODUCTO_TABLE = module.dynamodb_producto.dynamodb_table_id
    }
  }
}

resource "aws_lambda_function" "product_create" {
  function_name    = "cloud-presti-product-create"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.product_create_zip.output_path
  source_code_hash = data.archive_file.product_create_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids = [
      module.vpc.subnet_ids["10.0.2.0/24"],
      module.vpc.subnet_ids["10.0.5.0/24"],
    ]
    security_group_ids = [module.vpc.security_group_ids["lambda-sg"]]
  }

  environment {
    variables = {
      DYNAMODB_PRODUCTO_TABLE = module.dynamodb_producto.dynamodb_table_id
    }
  }
}

resource "aws_lambda_function" "product_update" {
  function_name    = "cloud-presti-product-update"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.product_update_zip.output_path
  source_code_hash = data.archive_file.product_update_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids = [
      module.vpc.subnet_ids["10.0.2.0/24"],
      module.vpc.subnet_ids["10.0.5.0/24"],
    ]
    security_group_ids = [module.vpc.security_group_ids["lambda-sg"]]
  }

  environment {
    variables = {
      DYNAMODB_PRODUCTO_TABLE = module.dynamodb_producto.dynamodb_table_id
    }
  }
}

resource "aws_lambda_function" "product_delete" {
  function_name    = "cloud-presti-product-delete"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.product_delete_zip.output_path
  source_code_hash = data.archive_file.product_delete_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids = [
      module.vpc.subnet_ids["10.0.2.0/24"],
      module.vpc.subnet_ids["10.0.5.0/24"],
    ]
    security_group_ids = [module.vpc.security_group_ids["lambda-sg"]]
  }

  environment {
    variables = {
      DYNAMODB_PRODUCTO_TABLE = module.dynamodb_producto.dynamodb_table_id
    }
  }
}

# --- API Gateway JWT authorizer ---

resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.simulations_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# --- Integrations ---

resource "aws_apigatewayv2_integration" "product_get" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.product_get.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "product_create" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.product_create.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "product_update" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.product_update.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "product_delete" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.product_delete.invoke_arn
  payload_format_version = "2.0"
}

# --- Routes ---

resource "aws_apigatewayv2_route" "get_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "GET /producto"
  target             = "integrations/${aws_apigatewayv2_integration.product_get.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "post_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "POST /producto"
  target             = "integrations/${aws_apigatewayv2_integration.product_create.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "put_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "PUT /producto/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.product_update.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "delete_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "DELETE /producto/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.product_delete.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

# --- Lambda permissions ---

resource "aws_lambda_permission" "api_gw_product_get" {
  statement_id  = "AllowExecutionFromAPIGatewayProductGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_product_create" {
  statement_id  = "AllowExecutionFromAPIGatewayProductCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_create.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_product_update" {
  statement_id  = "AllowExecutionFromAPIGatewayProductUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_update.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_product_delete" {
  statement_id  = "AllowExecutionFromAPIGatewayProductDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_delete.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}
