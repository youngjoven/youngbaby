#!/bin/bash
# ==============================================================
# APNs SNS Platform Application 생성 스크립트
# 실행 전 준비:
#   1. Apple Developer Console → Certificates → APNs Key (.p8 파일) 생성
#   2. Key ID, Team ID 메모
#   3. 아래 변수 설정 후 실행
# ==============================================================

set -e

# ── 설정 (실행 전 직접 입력) ─────────────────────────────────
STAGE="${STAGE:-dev}"                     # dev 또는 prod
REGION="ap-northeast-2"
APNS_KEY_FILE="${APNS_KEY_FILE}"          # 예: /path/to/AuthKey_XXXXXXXX.p8
APNS_KEY_ID="${APNS_KEY_ID}"             # Apple Developer에서 확인한 Key ID
TEAM_ID="${TEAM_ID}"                     # Apple Team ID
# ─────────────────────────────────────────────────────────────

if [ -z "$APNS_KEY_FILE" ] || [ -z "$APNS_KEY_ID" ] || [ -z "$TEAM_ID" ]; then
  echo "오류: APNS_KEY_FILE, APNS_KEY_ID, TEAM_ID 환경변수를 설정하세요."
  echo ""
  echo "사용 예:"
  echo "  APNS_KEY_FILE=/path/to/AuthKey_XXXXXXXX.p8 \\"
  echo "  APNS_KEY_ID=XXXXXXXX \\"
  echo "  TEAM_ID=XXXXXXXXXX \\"
  echo "  STAGE=dev ./setup-apns.sh"
  exit 1
fi

if [ ! -f "$APNS_KEY_FILE" ]; then
  echo "오류: $APNS_KEY_FILE 파일을 찾을 수 없습니다."
  exit 1
fi

# 개발(dev): APNS_SANDBOX / 운영(prod): APNS
if [ "$STAGE" = "prod" ]; then
  PLATFORM="APNS"
  APP_NAME="youngbaby-prod"
else
  PLATFORM="APNS_SANDBOX"
  APP_NAME="youngbaby-dev"
fi

echo "=== SNS Platform Application 생성 ==="
echo "  Stage:    $STAGE"
echo "  Platform: $PLATFORM"
echo "  Region:   $REGION"
echo ""

# .p8 키 파일 내용 읽기
PRIVATE_KEY=$(cat "$APNS_KEY_FILE")

# SNS Platform Application 생성
PLATFORM_ARN=$(aws sns create-platform-application \
  --region "$REGION" \
  --name "$APP_NAME" \
  --platform "$PLATFORM" \
  --attributes \
    "PlatformPrincipal=$APNS_KEY_ID" \
    "PlatformCredential=$PRIVATE_KEY" \
    "ApplePlatformTeamID=$TEAM_ID" \
    "ApplePlatformBundleID=com.youngbaby.app" \
  --query 'PlatformApplicationArn' \
  --output text)

echo "✅ SNS Platform Application ARN:"
echo "   $PLATFORM_ARN"
echo ""
echo "=== 다음 단계 ==="
echo "samconfig.toml의 parameter_overrides에 아래 값을 추가하세요:"
echo "  SnsApnsPlatformArn=$PLATFORM_ARN"
echo ""
echo "또는 배포 시 직접 전달:"
echo "  sam deploy --parameter-overrides \"Stage=$STAGE SnsApnsPlatformArn=$PLATFORM_ARN\""
