"""
디바이스 토큰 등록 Lambda 핸들러
POST /device/token - APNs 디바이스 토큰 → SNS Platform Endpoint 생성 후 DynamoDB 저장

요청 바디: {"deviceToken": "<APNs hex token>"}

동작:
  1. SNS CreatePlatformEndpoint 호출 → EndpointARN 획득
  2. DynamoDB youngbaby-device-tokens에 userId: [endpointArn, ...] 저장
  3. 엄마·아빠 모두 같은 userId로 등록 → 알람 발송 시 두 기기에 동시 전송

[보안] SNS_PLATFORM_APP_ARN은 template.yaml Parameter로 주입 (코드에 하드코딩 금지)
"""
import json
import os
import re
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
tokens_table = dynamodb.Table(os.environ["DEVICE_TOKENS_TABLE"])
sns = boto3.client("sns")

SNS_PLATFORM_APP_ARN = os.environ.get("SNS_PLATFORM_APP_ARN", "")


def _ok(body, status=200):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def _err(status, message):
    return _ok({"message": message}, status)


def _user_id(event):
    return event["requestContext"]["authorizer"]["claims"]["sub"]


def handler(event, context):
    uid = _user_id(event)
    body = json.loads(event.get("body") or "{}")
    device_token = body.get("deviceToken")

    if not device_token:
        return _err(400, "deviceToken is required")

    # SNS Platform App ARN 미설정 시 토큰만 저장 (알람은 미동작)
    endpoint_arn = None
    if SNS_PLATFORM_APP_ARN:
        endpoint_arn = _get_or_create_endpoint(device_token, uid)

    # DynamoDB에 EndpointARN 추가
    result = tokens_table.get_item(Key={"userId": uid})
    record = result.get("Item") or {"userId": uid, "endpointArns": []}

    if endpoint_arn and endpoint_arn not in record["endpointArns"]:
        record["endpointArns"].append(endpoint_arn)

    record["updatedAt"] = datetime.now(timezone.utc).isoformat()
    tokens_table.put_item(Item=record)

    return _ok({"message": "Device token registered"})


def _get_or_create_endpoint(device_token: str, uid: str) -> str | None:
    """SNS Platform Endpoint ARN을 생성하거나 기존 ARN을 반환한다."""
    try:
        resp = sns.create_platform_endpoint(
            PlatformApplicationArn=SNS_PLATFORM_APP_ARN,
            Token=device_token,
            CustomUserData=uid,
        )
        return resp["EndpointArn"]
    except sns.exceptions.InvalidParameterException as e:
        # 이미 존재하는 토큰 → 응답 메시지에서 ARN 추출
        match = re.search(r"Endpoint (arn:[^\s]+) already exists", str(e))
        if match:
            return match.group(1)
    except Exception:
        pass
    return None
