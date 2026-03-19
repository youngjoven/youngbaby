"""
알람 발송 Lambda 핸들러
EventBridge Scheduler가 직접 호출 (API Gateway 미사용)

입력 (EventBridge payload):
  {
    "userId": "cognito-sub-id",
    "nextFeedingTime": "2024-01-15T09:00:00Z"
  }

동작:
  DynamoDB에서 해당 userId의 SNS Endpoint ARN 목록 조회 →
  각 기기에 APNs 푸시 알림 발송 (SNS Publish)
"""
import json
import os
import decimal

import boto3

dynamodb = boto3.resource("dynamodb")
tokens_table = dynamodb.Table(os.environ["DEVICE_TOKENS_TABLE"])
sns = boto3.client("sns")

PUSH_TITLE = "아기 일기장"
PUSH_BODY = "수유할 시간입니다 🍼 분유 수유 후 기록해 주세요."


def handler(event, context):
    uid = event.get("userId")
    if not uid:
        return {"statusCode": 400, "body": "userId is required"}

    # 디바이스 토큰 조회
    result = tokens_table.get_item(Key={"userId": uid})
    item = result.get("Item")

    if not item or not item.get("endpointArns"):
        return {"statusCode": 200, "body": "No device registered"}

    # APNs 푸시 페이로드 (Production + Sandbox 모두 포함)
    apns_payload = json.dumps({
        "aps": {
            "alert": {"title": PUSH_TITLE, "body": PUSH_BODY},
            "sound": "default",
            "badge": 1,
        }
    })
    message = json.dumps({
        "APNS": apns_payload,
        "APNS_SANDBOX": apns_payload,
        "default": PUSH_BODY,
    })

    success, failed = 0, 0
    for endpoint_arn in item.get("endpointArns", []):
        try:
            sns.publish(
                TargetArn=endpoint_arn,
                Message=message,
                MessageStructure="json",
            )
            success += 1
        except sns.exceptions.EndpointDisabledException:
            # 기기가 앱 삭제 등으로 비활성화된 경우 → 토큰 목록에서 제거할 수 있으나 여기선 무시
            failed += 1
        except Exception:
            failed += 1

    return {
        "statusCode": 200,
        "body": json.dumps({"sent": success, "failed": failed}),
    }
