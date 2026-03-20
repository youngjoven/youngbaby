# ============================
# REST API + Cognito Authorizer
# ============================
resource "aws_api_gateway_rest_api" "main" {
  name = "youngbaby-api-${var.stage}"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [aws_cognito_user_pool.main.arn]
}

# ============================
# 경로(Resource) 정의
# /feedings, /feedings/{id}
# /bowels, /bowels/{id}
# /profile
# /advisor/advice
# /insights
# /alarm/schedule
# /device/token
# ============================
resource "aws_api_gateway_resource" "feedings" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "feedings"
}

resource "aws_api_gateway_resource" "feedings_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.feedings.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "bowels" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "bowels"
}

resource "aws_api_gateway_resource" "bowels_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bowels.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "profile" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "profile"
}

resource "aws_api_gateway_resource" "advisor" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "advisor"
}

resource "aws_api_gateway_resource" "advisor_advice" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.advisor.id
  path_part   = "advice"
}

resource "aws_api_gateway_resource" "insights" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "insights"
}

resource "aws_api_gateway_resource" "alarm" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "alarm"
}

resource "aws_api_gateway_resource" "alarm_schedule" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.alarm.id
  path_part   = "schedule"
}

resource "aws_api_gateway_resource" "device" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "device"
}

resource "aws_api_gateway_resource" "device_token" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.device.id
  path_part   = "token"
}

# ============================
# 엔드포인트 목록 (locals)
# for_each로 반복 생성 → 코드 중복 제거
# ============================
locals {
  endpoints = {
    feedings_post   = { resource_id = aws_api_gateway_resource.feedings.id,       http_method = "POST",   function = aws_lambda_function.feedings }
    feedings_get    = { resource_id = aws_api_gateway_resource.feedings.id,       http_method = "GET",    function = aws_lambda_function.feedings }
    feedings_delete = { resource_id = aws_api_gateway_resource.feedings_id.id,    http_method = "DELETE", function = aws_lambda_function.feedings }
    bowels_post     = { resource_id = aws_api_gateway_resource.bowels.id,         http_method = "POST",   function = aws_lambda_function.bowels }
    bowels_get      = { resource_id = aws_api_gateway_resource.bowels.id,         http_method = "GET",    function = aws_lambda_function.bowels }
    bowels_delete   = { resource_id = aws_api_gateway_resource.bowels_id.id,      http_method = "DELETE", function = aws_lambda_function.bowels }
    profile_get     = { resource_id = aws_api_gateway_resource.profile.id,        http_method = "GET",    function = aws_lambda_function.profile }
    profile_put     = { resource_id = aws_api_gateway_resource.profile.id,        http_method = "PUT",    function = aws_lambda_function.profile }
    advisor_post    = { resource_id = aws_api_gateway_resource.advisor_advice.id,  http_method = "POST",   function = aws_lambda_function.advisor }
    insights_get    = { resource_id = aws_api_gateway_resource.insights.id,       http_method = "GET",    function = aws_lambda_function.insights }
    alarm_post      = { resource_id = aws_api_gateway_resource.alarm_schedule.id,  http_method = "POST",   function = aws_lambda_function.alarm_schedule }
    device_post     = { resource_id = aws_api_gateway_resource.device_token.id,   http_method = "POST",   function = aws_lambda_function.device }
  }
}

# Cognito 인증 메서드 (12개 엔드포인트 일괄 생성)
resource "aws_api_gateway_method" "endpoints" {
  for_each      = local.endpoints
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value.resource_id
  http_method   = each.value.http_method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Lambda Proxy 통합 (12개 일괄 생성)
resource "aws_api_gateway_integration" "endpoints" {
  for_each                = local.endpoints
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.endpoints[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.function.invoke_arn

  depends_on = [aws_api_gateway_method.endpoints]
}

# ============================
# Lambda 호출 권한 (API Gateway → 각 Lambda)
# ============================
resource "aws_lambda_permission" "feedings" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feedings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "bowels" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bowels.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "profile" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.profile.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "advisor" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.advisor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "insights" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.insights.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "alarm_schedule" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_schedule.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "device" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.device.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ============================
# 배포(Deployment) + 스테이지(Stage)
# triggers: 엔드포인트 변경 감지 → 자동 재배포
# ============================
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.feedings.id,
      aws_api_gateway_resource.feedings_id.id,
      aws_api_gateway_resource.bowels.id,
      aws_api_gateway_resource.bowels_id.id,
      aws_api_gateway_resource.profile.id,
      aws_api_gateway_resource.advisor_advice.id,
      aws_api_gateway_resource.insights.id,
      aws_api_gateway_resource.alarm_schedule.id,
      aws_api_gateway_resource.device_token.id,
      aws_api_gateway_method.endpoints,
      aws_api_gateway_integration.endpoints,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.endpoints]
}

resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = var.stage
}
