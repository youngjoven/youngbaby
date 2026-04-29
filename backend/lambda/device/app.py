"""
디바이스 토큰 등록 Lambda 핸들러
POST /device/token - APNs 디바이스 토큰 → SNS Platform Endpoint 생성 후 DynamoDB 저장
"""
import json
import os
import re
from datetime import datetime, timezone

import boto3
from common import ok, err, user_id
from common.validation import parse_json_body

dynamodb = boto3.resource("dynamodb")
tokens_table = dynamodb.Table(os.environ["DEVICE_TOKENS_TABLE"])
sns = boto3.client("sns")

SNS_PLATFORM_APP_ARN = os.environ.get("SNS_PLATFORM_APP_ARN", "")


def handler(event, context):
    uid = user_id(event)
    body = parse_json_body(event)
    if body is None:
        return err(400, "Invalid JSON body")

    device_token = body.get("deviceToken")
    if not device_token:
        return err(400, "deviceToken is required")

    endpoint_arn = None
    if SNS_PLATFORM_APP_ARN:
        endpoint_arn = _get_or_create_endpoint(device_token, uid)

    # Atomic update로 Race Condition 방지
    if endpoint_arn:
        tokens_table.update_item(
            Key={"userId": uid},
            UpdateExpression="ADD endpointArns :arn SET updatedAt = :ts",
            ExpressionAttributeValues={
                ":arn": {endpoint_arn},
                ":ts": datetime.now(timezone.utc).isoformat(),
            },
        )
    else:
        tokens_table.update_item(
            Key={"userId": uid},
            UpdateExpression="SET updatedAt = :ts",
            ExpressionAttributeValues={
                ":ts": datetime.now(timezone.utc).isoformat(),
            },
        )

    return ok({"message": "Device token registered"})


def _get_or_create_endpoint(device_token: str, uid: str) -> str | None:
    try:
        resp = sns.create_platform_endpoint(
            PlatformApplicationArn=SNS_PLATFORM_APP_ARN,
            Token=device_token,
            CustomUserData=uid,
        )
        return resp["EndpointArn"]
    except sns.exceptions.InvalidParameterException as e:
        match = re.search(r"Endpoint (arn:[^\s]+) already exists", str(e))
        if match:
            return match.group(1)
    except Exception:
        pass
    return None
