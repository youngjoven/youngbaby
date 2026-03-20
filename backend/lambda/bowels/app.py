"""
배변 기록 Lambda 핸들러
POST /bowels  - 배변 기록 생성
GET  /bowels  - 배변 기록 목록 조회 (?from=ISO8601&to=ISO8601)
DELETE /bowels/{id} - 배변 기록 삭제 (id = bowelTime)
"""
import json
import os
import decimal
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["BOWELS_TABLE"])


class _DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)


def _ok(body, status=200):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, cls=_DecimalEncoder, ensure_ascii=False),
    }


def _err(status, message):
    return _ok({"message": message}, status)


def _user_id(event):
    return event["requestContext"]["authorizer"]["claims"]["sub"]


def handler(event, context):
    method = event["httpMethod"]
    uid = _user_id(event)

    if method == "POST":
        return _create(event, uid)
    if method == "GET":
        return _list(event, uid)
    if method == "DELETE":
        return _delete(event, uid)
    return _err(405, "Method Not Allowed")


def _create(event, uid):
    body = json.loads(event.get("body") or "{}")
    bowel_time = body.get("bowelTime")
    condition = body.get("condition")

    if not bowel_time or not condition:
        return _err(400, "bowelTime and condition are required")

    # condition 유효성 검사
    allowed = {"hard", "normal", "soft"}
    if condition not in allowed:
        return _err(400, f"condition must be one of {allowed}")

    item = {
        "userId": uid,
        "bowelTime": bowel_time,
        "condition": condition,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    table.put_item(Item=item)
    return _ok(item, 201)


def _list(event, uid):
    params = event.get("queryStringParameters") or {}
    from_time = params.get("from")
    to_time = params.get("to")

    if from_time and to_time:
        result = table.query(
            KeyConditionExpression=Key("userId").eq(uid)
            & Key("bowelTime").between(from_time, to_time),
            ScanIndexForward=False,
        )
    else:
        result = table.query(
            KeyConditionExpression=Key("userId").eq(uid),
            ScanIndexForward=False,
            Limit=100,
        )
    return _ok(result.get("Items", []))


def _delete(event, uid):
    path_params = event.get("pathParameters") or {}
    bowel_time = path_params.get("id")  # id = bowelTime (sort key)

    if not bowel_time:
        return _err(400, "bowelTime (id) is required")

    table.delete_item(Key={"userId": uid, "bowelTime": bowel_time})
    return _ok({"message": "deleted"})
