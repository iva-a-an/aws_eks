## Provision lambda function

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = var.tags
}

resource "aws_iam_policy" "lambda_secrets_manager" {
  name        = "lambda_secrets_manager"
  description = "Allows Lambda function to create secrets in Secrets Manager"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret"
      ],
      "Resource": "*"
    }
  ]
}
EOF
tags = var.tags
}


## Attach roles
resource "aws_iam_policy_attachment" "lambda_secrets_manager_attach" {
  name       = "lambda_secrets_manager_attach"
  roles      = [aws_iam_role.iam_for_lambda.name]
  policy_arn = aws_iam_policy.lambda_secrets_manager.arn
}

## Require to allow lambda to write logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "demo_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  ## TODO: Change the filename to be variable relalative to the project root
  filename      = var.app_file
  function_name = "demo"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  timeout       =  "5"

  ## TODO: Change the filename to be variable relalative to the project root
  source_code_hash = filebase64sha256("${var.app_file}")

  runtime = "python3.12"

  environment {
    variables = {}
  }
  tags = var.tags
}


resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "run_lambda_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = aws_lambda_function.demo_lambda.function_name
  arn       = aws_lambda_function.demo_lambda.arn  
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

## LOGGING
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.demo_lambda.function_name}"
  retention_in_days = 7
  tags = var.tags
}