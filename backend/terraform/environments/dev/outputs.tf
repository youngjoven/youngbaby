# ============================================================
# 배포 완료 후 이 값들을 iOS Config.xcconfig에 입력하세요
# ============================================================

output "api_url" {
  description = "API Gateway URL → iOS Config.xcconfig의 API_BASE_URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage}"
}

output "user_pool_id" {
  description = "Cognito User Pool ID → iOS Config.xcconfig의 COGNITO_USER_POOL_ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID → iOS Config.xcconfig의 COGNITO_CLIENT_ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "cognito_region" {
  description = "Cognito 리전 → iOS Config.xcconfig의 COGNITO_REGION"
  value       = var.aws_region
}
