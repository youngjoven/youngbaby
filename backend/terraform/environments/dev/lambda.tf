# ============================
# 공통 환경변수 (locals)
# ============================
locals {
  lambda_env = {
    FEEDINGS_TABLE      = aws_dynamodb_table.feedings.name
    BOWELS_TABLE        = aws_dynamodb_table.bowels.name
    PROFILES_TABLE      = aws_dynamodb_table.profiles.name
    INSIGHTS_TABLE      = aws_dynamodb_table.insights.name
    DEVICE_TOKENS_TABLE = aws_dynamodb_table.device_tokens.name
    LLM_QUOTA_TABLE     = aws_dynamodb_table.llm_quota.name
    BEDROCK_REGION      = var.aws_region
  }

  lambda_zip_dir = "${path.module}/.lambda_zips"
}

# ============================
# archive_file: Lambda 코드 → zip 패키징
# source_code_hash로 코드 변경 자동 감지 후 재배포
# ============================
data "archive_file" "feedings" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/feedings"
  output_path = "${local.lambda_zip_dir}/feedings.zip"
}

data "archive_file" "bowels" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/bowels"
  output_path = "${local.lambda_zip_dir}/bowels.zip"
}

data "archive_file" "profile" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/profile"
  output_path = "${local.lambda_zip_dir}/profile.zip"
}

data "archive_file" "advisor" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/advisor"
  output_path = "${local.lambda_zip_dir}/advisor.zip"
}

data "archive_file" "insights" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/insights"
  output_path = "${local.lambda_zip_dir}/insights.zip"
}

data "archive_file" "alarm" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/alarm"
  output_path = "${local.lambda_zip_dir}/alarm.zip"
}

data "archive_file" "alarm_delivery" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/alarm_delivery"
  output_path = "${local.lambda_zip_dir}/alarm_delivery.zip"
}

data "archive_file" "device" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/device"
  output_path = "${local.lambda_zip_dir}/device.zip"
}

data "archive_file" "account" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/account"
  output_path = "${local.lambda_zip_dir}/account.zip"
}

# ============================
# Lambda: 수유 기록 CRUD
# ============================
resource "aws_lambda_function" "feedings" {
  function_name    = "youngbaby-feedings-${var.stage}"
  filename         = data.archive_file.feedings.output_path
  source_code_hash = data.archive_file.feedings.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "feedings" {
  name              = "/aws/lambda/youngbaby-feedings-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 배변 기록 CRUD
# ============================
resource "aws_lambda_function" "bowels" {
  function_name    = "youngbaby-bowels-${var.stage}"
  filename         = data.archive_file.bowels.output_path
  source_code_hash = data.archive_file.bowels.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "bowels" {
  name              = "/aws/lambda/youngbaby-bowels-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 프로필 조회/수정
# ============================
resource "aws_lambda_function" "profile" {
  function_name    = "youngbaby-profile-${var.stage}"
  filename         = data.archive_file.profile.output_path
  source_code_hash = data.archive_file.profile.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "profile" {
  name              = "/aws/lambda/youngbaby-profile-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: AI 어드바이저 (Bedrock, timeout 60s)
# ============================
resource "aws_lambda_function" "advisor" {
  function_name    = "youngbaby-advisor-${var.stage}"
  filename         = data.archive_file.advisor.output_path
  source_code_hash = data.archive_file.advisor.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "advisor" {
  name              = "/aws/lambda/youngbaby-advisor-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 데이터 인사이트 (Bedrock, timeout 60s)
# ============================
resource "aws_lambda_function" "insights" {
  function_name    = "youngbaby-insights-${var.stage}"
  filename         = data.archive_file.insights.output_path
  source_code_hash = data.archive_file.insights.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "insights" {
  name              = "/aws/lambda/youngbaby-insights-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 알람 예약 (EventBridge Scheduler)
# ============================
resource "aws_lambda_function" "alarm_schedule" {
  function_name    = "youngbaby-alarm-schedule-${var.stage}"
  filename         = data.archive_file.alarm.output_path
  source_code_hash = data.archive_file.alarm.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(local.lambda_env, {
      SCHEDULER_ROLE_ARN = aws_iam_role.scheduler_exec.arn
      ALARM_DELIVERY_ARN = aws_lambda_function.alarm_delivery.arn
    })
  }
}

resource "aws_cloudwatch_log_group" "alarm_schedule" {
  name              = "/aws/lambda/youngbaby-alarm-schedule-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 알람 발송 (SNS → APNs)
# ============================
resource "aws_lambda_function" "alarm_delivery" {
  function_name    = "youngbaby-alarm-delivery-${var.stage}"
  filename         = data.archive_file.alarm_delivery.output_path
  source_code_hash = data.archive_file.alarm_delivery.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(local.lambda_env, {
      SNS_PLATFORM_APP_ARN = var.sns_apns_platform_arn
    })
  }
}

resource "aws_cloudwatch_log_group" "alarm_delivery" {
  name              = "/aws/lambda/youngbaby-alarm-delivery-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 디바이스 토큰 등록
# ============================
resource "aws_lambda_function" "device" {
  function_name    = "youngbaby-device-${var.stage}"
  filename         = data.archive_file.device.output_path
  source_code_hash = data.archive_file.device.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(local.lambda_env, {
      SNS_PLATFORM_APP_ARN = var.sns_apns_platform_arn
    })
  }
}

resource "aws_cloudwatch_log_group" "device" {
  name              = "/aws/lambda/youngbaby-device-${var.stage}"
  retention_in_days = 30
}

# ============================
# Lambda: 계정 삭제
# ============================
resource "aws_lambda_function" "account" {
  function_name    = "youngbaby-account-${var.stage}"
  filename         = data.archive_file.account.output_path
  source_code_hash = data.archive_file.account.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(local.lambda_env, {
      USER_POOL_ID = aws_cognito_user_pool.main.id
    })
  }
}

resource "aws_cloudwatch_log_group" "account" {
  name              = "/aws/lambda/youngbaby-account-${var.stage}"
  retention_in_days = 30
}
