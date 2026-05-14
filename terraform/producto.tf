# --- Archives ---

data "archive_file" "producto_get_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/producto/get"
  output_path = "${path.root}/.terraform/archives/producto_get.zip"
}

data "archive_file" "producto_post_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/producto/post"
  output_path = "${path.root}/.terraform/archives/producto_post.zip"
}

data "archive_file" "producto_put_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/producto/put"
  output_path = "${path.root}/.terraform/archives/producto_put.zip"
}

data "archive_file" "producto_delete_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/producto/delete"
  output_path = "${path.root}/.terraform/archives/producto_delete.zip"
}

# --- Lambda functions ---

resource "aws_lambda_function" "producto_get" {
  function_name    = "cloud-presti-producto-get"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.producto_get_zip.output_path
  source_code_hash = data.archive_file.producto_get_zip.output_base64sha256
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
      DB_HOST    = aws_db_proxy.main.endpoint
      DB_PORT    = "5432"
      DB_NAME    = "cloudpresti"
      SECRET_ARN = module.rds.db_instance_master_user_secret_arn
    }
  }
}

resource "aws_lambda_function" "producto_post" {
  function_name    = "cloud-presti-producto-post"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.producto_post_zip.output_path
  source_code_hash = data.archive_file.producto_post_zip.output_base64sha256
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
      DB_HOST    = aws_db_proxy.main.endpoint
      DB_PORT    = "5432"
      DB_NAME    = "cloudpresti"
      SECRET_ARN = module.rds.db_instance_master_user_secret_arn
    }
  }
}

resource "aws_lambda_function" "producto_put" {
  function_name    = "cloud-presti-producto-put"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.producto_put_zip.output_path
  source_code_hash = data.archive_file.producto_put_zip.output_base64sha256
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
      DB_HOST    = aws_db_proxy.main.endpoint
      DB_PORT    = "5432"
      DB_NAME    = "cloudpresti"
      SECRET_ARN = module.rds.db_instance_master_user_secret_arn
    }
  }
}

resource "aws_lambda_function" "producto_delete" {
  function_name    = "cloud-presti-producto-delete"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.producto_delete_zip.output_path
  source_code_hash = data.archive_file.producto_delete_zip.output_base64sha256
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
      DB_HOST    = aws_db_proxy.main.endpoint
      DB_PORT    = "5432"
      DB_NAME    = "cloudpresti"
      SECRET_ARN = module.rds.db_instance_master_user_secret_arn
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

resource "aws_apigatewayv2_integration" "producto_get" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.producto_get.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "producto_post" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.producto_post.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "producto_put" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.producto_put.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "producto_delete" {
  api_id                 = aws_apigatewayv2_api.simulations_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.producto_delete.invoke_arn
  payload_format_version = "2.0"
}

# --- Routes ---

resource "aws_apigatewayv2_route" "get_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "GET /producto"
  target             = "integrations/${aws_apigatewayv2_integration.producto_get.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "post_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "POST /producto"
  target             = "integrations/${aws_apigatewayv2_integration.producto_post.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "put_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "PUT /producto/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.producto_put.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

resource "aws_apigatewayv2_route" "delete_producto" {
  api_id             = aws_apigatewayv2_api.simulations_api.id
  route_key          = "DELETE /producto/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.producto_delete.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
}

# --- Lambda permissions ---

resource "aws_lambda_permission" "api_gw_producto_get" {
  statement_id  = "AllowExecutionFromAPIGatewayProductoGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producto_get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_producto_post" {
  statement_id  = "AllowExecutionFromAPIGatewayProductoPost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producto_post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_producto_put" {
  statement_id  = "AllowExecutionFromAPIGatewayProductoPut"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producto_put.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_producto_delete" {
  statement_id  = "AllowExecutionFromAPIGatewayProductoDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producto_delete.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.simulations_api.execution_arn}/*/*"
}
