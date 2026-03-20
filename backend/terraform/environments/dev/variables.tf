variable "stage" {
  type        = string
  default     = "dev"
  description = "배포 스테이지"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS 리전"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.100.0.0/16"
  description = "VPC CIDR 블록"
}

variable "private_subnet_a_cidr" {
  type        = string
  default     = "10.100.1.0/24"
  description = "Private Subnet A (us-east-1a)"
}

variable "private_subnet_b_cidr" {
  type        = string
  default     = "10.100.2.0/24"
  description = "Private Subnet B (us-east-1b)"
}

variable "sns_apns_platform_arn" {
  type        = string
  default     = ""
  description = "SNS APNs Platform ARN (Apple Developer 계정 취득 후 입력)"
}

variable "waf_rate_limit" {
  type        = number
  default     = 30
  description = "WAF Rate Limit (요청 수/분, IP 기준)"
}
