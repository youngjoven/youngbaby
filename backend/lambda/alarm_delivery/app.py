"""
알람 발송 Lambda 핸들러
EventBridge Scheduler가 직접 호출 (API Gateway 미사용)
"""
import json
import os

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

    result = tokens_table.get_item(Key={"userId": uid})
    item = result.get("Item")

    if not item or not item.get("endpointArns"):
        return {"statusCode": 200, "body": "No device registered"}

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

    # endpointArns가 SS(String Set)일 수 있으므로 list로 변환
    arns = item.get("endpointArns", [])
    if isinstance(arns, set):
        arns = list(arns)

    success, failed = 0, 0
    for endpoint_arn in arns:
        try:
            sns.publish(
                TargetArn=endpoint_arn,
                Message=message,
                MessageStructure="json",
            )
            success += 1
        except sns.exceptions.EndpointDisabledException:
            failed += 1
        except Exception:
            failed += 1

    return {
        "statusCode": 200,
        "body": json.dumps({"sent": success, "failed": failed}),
    }
