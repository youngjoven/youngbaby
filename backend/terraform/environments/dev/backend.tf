# ============================================================
# Remote Backend 설정
#
# bootstrap/ 실행 후 출력된 값으로 아래를 채우세요:
#   bucket         = bootstrap output: state_bucket_name
#   dynamodb_table = bootstrap output: lock_table_name  (= "youngbaby-terraform-lock")
#
# 설정 후:
#   terraform init   (처음 한 번)
# ============================================================
terraform {
  backend "s3" {
    bucket         = "youngbaby-terraform-state-[ACCOUNT_ID]"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "youngbaby-terraform-lock"
    encrypt        = true
  }
}
