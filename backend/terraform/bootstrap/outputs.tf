output "state_bucket_name" {
  description = "S3 버킷 이름 → environments/dev/backend.tf의 bucket에 입력"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB 잠금 테이블 이름 → environments/dev/backend.tf의 dynamodb_table에 입력"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
