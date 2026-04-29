"""
배변 기록 Lambda 핸들러
POST /bowels  - 배변 기록 생성
GET  /bowels  - 배변 기록 목록 조회 (?from=ISO8601&to=ISO8601)
DELETE /bowels/{id} - 배변 기록 삭제 (id = bowelTime)
"""
import os
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key
from common import ok, err, user_id
from common.validation import parse_json_body, validate_iso8601

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["BOWELS_TABLE"])

ALLOWED_CONDITIONS = {"hard", "normal", "soft"}


def handler(event, context):
    method = event["httpMethod"]
    uid = user_id(event)

    if method == "POST":
        return _create(event, uid)
    if method == "GET":
        return _list(event, uid)
    if method == "DELETE":
        return _delete(event, uid)
    return err(405, "Method Not Allowed")


def _create(event, uid):
    body = parse_json_body(event)
    if body is None:
        return err(400, "Invalid JSON body")

    bowel_time = body.get("bowelTime")
    condition = body.get("condition")

    if e := validate_iso8601(bowel_time, "bowelTime"):
        return err(400, e)
    if not condition or condition not in ALLOWED_CONDITIONS:
        return err(400, f"condition must be one of {ALLOWED_CONDITIONS}")

    item = {
        "userId": uid,
        "bowelTime": bowel_time,
        "condition": condition,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    table.put_item(Item=item)
    return ok(item, 201)


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
    return ok(result.get("Items", []))


def _delete(event, uid):
    path_params = event.get("pathParameters") or {}
    bowel_time = path_params.get("id")

    if not bowel_time:
        return err(400, "bowelTime (id) is required")

    table.delete_item(Key={"userId": uid, "bowelTime": bowel_time})
    return ok({"message": "deleted"})
