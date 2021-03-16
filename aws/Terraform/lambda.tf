#---------------------------------------------
# Lambda Authorization
#---------------------------------------------

resource "aws_lambda_function" "lambda_opa_auth" {
  function_name = "opa_auth"
  description   = "opa auth lambda function"

  #Runtime settings
  handler = "handler.lambda_handler"
  runtime = "python3.6"

  role = aws_iam_role.opa_auth_lambda_role.arn

  #Basic settings
  memory_size = 512
  timeout     = 120

  source_code_hash = data.archive_file.lambda_opa_auth_zip_pkg.output_base64sha256
  filename         = data.archive_file.lambda_opa_auth_zip_pkg.output_path


  environment {
    variables = {
      
      PDP_HOST = aws_instance.buildsec-pdp.public_dns
      PDP_POLICY_PATH = var.POLICY_PATH
    
    }
  }
/*
  tags = {
   
  }
  */
}

data "archive_file" "lambda_opa_auth_zip_pkg" {
  source_dir  = "../opa_auth_lambda"
  output_path = "handler.zip"
  type        = "zip"
}

resource "aws_lambda_function_event_invoke_config" "example" {
  function_name                = aws_lambda_function.lambda_opa_auth.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 2
}

#---------------------------------------------
# LAMBDA TASK ROLES & POLICY
#---------------------------------------------

resource "aws_iam_role" "opa_auth_lambda_role" {
  name               = "opa-auth-role"
  assume_role_policy = file("iam/trust_relationship.json")
}

data "template_file" "lambda_opa_auth_policy_template" {
    template = file("iam/iam_policy.json")
}

resource "aws_iam_role_policy" "lambda_opa_auth_iam_policy" {
  name   = "lambda_opa_auth_iam_policy"
  role   = aws_iam_role.opa_auth_lambda_role.id
  policy = data.template_file.lambda_opa_auth_policy_template.rendered
}