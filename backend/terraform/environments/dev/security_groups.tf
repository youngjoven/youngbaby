# ============================
# Lambda Security Group
# 아웃바운드 HTTPS(443)만 허용
# 인터넷 차단은 라우팅 레벨 (IGW/NAT 없음)
# ============================
resource "aws_security_group" "lambda" {
  name        = "youngbaby-lambda-sg-${var.stage}"
  description = "Lambda outbound HTTPS only - internet blocked at routing level (no IGW/NAT)"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS: S3/DynamoDB via Gateway EP, Bedrock/SNS/Logs/Scheduler via Interface EP"
  }

  tags = { Name = "youngbaby-lambda-sg-${var.stage}" }
}

# ============================
# VPC Endpoint Security Group
# Lambda SG 에서만 인바운드 허용
# ============================
resource "aws_security_group" "vpc_endpoint" {
  name        = "youngbaby-endpoint-sg-${var.stage}"
  description = "Interface VPC Endpoints - accept HTTPS from Lambda only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "HTTPS from Lambda functions only"
  }

  tags = { Name = "youngbaby-endpoint-sg-${var.stage}" }
}
