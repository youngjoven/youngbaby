# ============================
# Gateway Endpoints (무료)
# Route Table에 경로 추가 → S3/DynamoDB 트래픽이 AWS 백본으로 이동
# ============================
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags = { Name = "youngbaby-s3-ep-${var.stage}" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags = { Name = "youngbaby-dynamodb-ep-${var.stage}" }
}

# ============================
# Interface Endpoints (단일 AZ: us-east-1a만 사용)
# AZ당 $0.01/hr → 1 AZ만 사용해 비용 절반으로 절감
# cloudwatch_logs: Lambda 로그는 Lambda 서비스 인프라가 직접 처리 → 엔드포인트 불필요
# ============================
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  tags = { Name = "youngbaby-bedrock-ep-${var.stage}" }
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  tags = { Name = "youngbaby-sns-ep-${var.stage}" }
}

resource "aws_vpc_endpoint" "scheduler" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.scheduler"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  tags = { Name = "youngbaby-scheduler-ep-${var.stage}" }
}
