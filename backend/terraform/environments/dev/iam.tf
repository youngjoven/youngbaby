data "aws_caller_identity" "current" {}

# ============================
# Lambda 공통 실행 역할
# ============================
resource "aws_iam_role" "lambda_exec" {
  name = "youngbaby-lambda-exec-${var.stage}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lambda in VPC 필수 권한 (ENI 생성/삭제)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# DynamoDB CRUD (앱 데이터 5개 테이블)
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "youngbaby-lambda-dynamodb-${var.stage}"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWriteItem",
      ]
      Resource = [
        aws_dynamodb_table.feedings.arn,
        aws_dynamodb_table.bowels.arn,
        aws_dynamodb_table.profiles.arn,
        aws_dynamodb_table.insights.arn,
        aws_dynamodb_table.device_tokens.arn,
        aws_dynamodb_table.llm_quota.arn,
      ]
    }]
  })
}

# Bedrock Claude Sonnet 4 호출 (Cross-region Inference Profile)
resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "youngbaby-lambda-bedrock-${var.stage}"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "bedrock:InvokeModel"
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-20250514-v1:0",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-sonnet-4-20250514-v1:0",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe",
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge Scheduler 알람 예약 (youngbaby-alarm-* 스케줄만)
resource "aws_iam_role_policy" "lambda_scheduler" {
  name = "youngbaby-lambda-scheduler-${var.stage}"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:UpdateSchedule",
          "scheduler:DeleteSchedule",
        ]
        Resource = "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/youngbaby-alarm-*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.scheduler_exec.arn
      }
    ]
  })
}

# SNS: 엔드포인트 발행 + APNs 플랫폼 엔드포인트 관리
resource "aws_iam_role_policy" "lambda_sns" {
  name = "youngbaby-lambda-sns-${var.stage}"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:CreatePlatformEndpoint",
          "sns:SetEndpointAttributes",
          "sns:GetEndpointAttributes",
        ]
        Resource = [
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:app/APNS_SANDBOX/*",
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/*",
        ]
      }
    ]
  })
}

# Cognito AdminDeleteUser (계정 삭제 Lambda 전용)
resource "aws_iam_role_policy" "lambda_cognito_delete" {
  name = "youngbaby-lambda-cognito-delete-${var.stage}"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cognito-idp:AdminDeleteUser"
      Resource = aws_cognito_user_pool.main.arn
    }]
  })
}

# ============================
# EventBridge Scheduler → AlarmDelivery Lambda 호출 역할
# ============================
resource "aws_iam_role" "scheduler_exec" {
  name = "youngbaby-scheduler-role-${var.stage}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda" {
  name = "InvokeAlarmDeliveryLambda"
  role = aws_iam_role.scheduler_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.alarm_delivery.arn
    }]
  })
}
