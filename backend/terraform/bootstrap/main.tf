# ============================================================
# Bootstrap: Terraform 상태 관리용 리소스 (1회만 실행)
#
# 실행 방법:
#   cd backend/terraform/bootstrap
#   terraform init
#   terraform apply
#
# 주의: 이 리소스들은 Terraform 상태 파일이 없는 상태에서
#        로컬(local) 상태로 생성됩니다. 생성 후 절대 삭제 금지.
# ============================================================

data "aws_caller_identity" "current" {}

# ============================
# S3 버킷: Terraform 상태 파일 저장
# 버킷 이름에 Account ID를 포함해 전 세계 유일성 보장
# ============================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "youngbaby-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "youngbaby-terraform-state"
    Purpose = "Terraform remote state storage"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================
# DynamoDB 테이블: Terraform 상태 잠금
# Primary Key는 반드시 LockID (String) 여야 함
# ============================
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "youngbaby-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "youngbaby-terraform-lock"
    Purpose = "Terraform state locking"
  }
}
