"""
프로필 Lambda 핸들러
GET /profile  - 프로필 조회
PUT /profile  - 프로필 생성/수정
"""
import json
import os
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["PROFILES_TABLE"])


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
    method = event["httpMethod"]
    uid = _user_id(event)

    if method == "GET":
        return _get(uid)
    if method == "PUT":
        return _put(event, uid)
    return _err(405, "Method Not Allowed")


def _get(uid):
    result = table.get_item(Key={"userId": uid})
    item = result.get("Item")
    if not item:
        return _err(404, "Profile not found")
    return _ok(item)


def _put(event, uid):
    body = json.loads(event.get("body") or "{}")

    baby_name = body.get("babyName", "")
    baby_birth_date = body.get("babyBirthDate", "")
    mother_name = body.get("motherName", "")

    if not baby_name or not baby_birth_date:
        return _err(400, "babyName and babyBirthDate are required")

    item = {
        "userId": uid,
        "babyName": baby_name,
        "babyBirthDate": baby_birth_date,
        "motherName": mother_name,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
    table.put_item(Item=item)
    return _ok(item)
