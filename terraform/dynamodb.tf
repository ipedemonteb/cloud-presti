module "dynamodb_simulations" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.4.0"

  name      = "${var.project_name}-simulations"
  hash_key  = "sub"
  range_key = "sk"

  attributes = [
    { name = "sub", type = "S" },
    { name = "sk",  type = "S" },
  ]

  billing_mode = "PAY_PER_REQUEST"
  tags         = { Project = var.project_name }
}

module "dynamodb_fintech" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.4.0"

  name     = "${var.project_name}-fintech"
  hash_key = "sub"

  attributes = [
    { name = "sub", type = "S" },
  ]

  billing_mode = "PAY_PER_REQUEST"
  tags         = { Project = var.project_name }
}

module "dynamodb_producto" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.4.0"

  name      = "${var.project_name}-producto"
  hash_key  = "sub"
  range_key = "producto_id"

  attributes = [
    { name = "sub",         type = "S" },
    { name = "producto_id", type = "S" },
  ]

  billing_mode = "PAY_PER_REQUEST"
  tags         = { Project = var.project_name }
}

module "dynamodb_usuario" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.4.0"

  name      = "${var.project_name}-usuario"
  hash_key  = "sub"
  range_key = "cuit"

  attributes = [
    { name = "sub",  type = "S" },
    { name = "cuit", type = "S" },
  ]

  billing_mode = "PAY_PER_REQUEST"
  tags         = { Project = var.project_name }
}
