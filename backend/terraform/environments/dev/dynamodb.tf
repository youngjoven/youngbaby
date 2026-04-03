# ============================
# DynamoDB 앱 데이터 테이블 (전체 PITR 활성화)
# lifecycle.prevent_destroy = true → terraform destroy 시 삭제 방지
# ============================

resource "aws_dynamodb_table" "feedings" {
  name         = "youngbaby-feeding-records-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "feedingTime"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "feedingTime"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "youngbaby-feeding-records-${var.stage}" }
}

resource "aws_dynamodb_table" "bowels" {
  name         = "youngbaby-bowel-records-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "bowelTime"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "bowelTime"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "youngbaby-bowel-records-${var.stage}" }
}

resource "aws_dynamodb_table" "profiles" {
  name         = "youngbaby-user-profiles-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "youngbaby-user-profiles-${var.stage}" }
}

resource "aws_dynamodb_table" "insights" {
  name         = "youngbaby-insights-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "generatedAt"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "generatedAt"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "youngbaby-insights-${var.stage}" }
}

resource "aws_dynamodb_table" "device_tokens" {
  name         = "youngbaby-device-tokens-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "youngbaby-device-tokens-${var.stage}" }
}

# ============================
# LLM 일일 호출 할당량 테이블
# userId + date(YYYY-MM-DD UTC) 기준 원자적 카운터 + 마지막 응답 캐시
# TTL 2일 → 자동 만료 (복구 불필요 → PITR/prevent_destroy 미적용)
# ============================
resource "aws_dynamodb_table" "llm_quota" {
  name         = "youngbaby-llm-quota-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "date"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "date"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = { Name = "youngbaby-llm-quota-${var.stage}" }
}
