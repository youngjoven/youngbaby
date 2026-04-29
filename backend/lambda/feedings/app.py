"""
수유 기록 Lambda 핸들러
POST /feedings  - 수유 기록 생성
GET  /feedings  - 수유 기록 목록 조회 (?from=ISO8601&to=ISO8601)
DELETE /feedings/{id} - 수유 기록 삭제 (id = feedingTime)
"""
import os
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key
from common import ok, err, user_id
from common.validation import parse_json_body, validate_iso8601, validate_range

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["FEEDINGS_TABLE"])


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

    feeding_time = body.get("feedingTime")
    amount_ml = body.get("amountMl")

    if e := validate_iso8601(feeding_time, "feedingTime"):
        return err(400, e)
    if e := validate_range(amount_ml, "amountMl", 1, 500):
        return err(400, e)

    item = {
        "userId": uid,
        "feedingTime": feeding_time,
        "amountMl": int(amount_ml),
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
            & Key("feedingTime").between(from_time, to_time),
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
    feeding_time = path_params.get("id")

    if not feeding_time:
        return err(400, "feedingTime (id) is required")

    table.delete_item(Key={"userId": uid, "feedingTime": feeding_time})
    return ok({"message": "deleted"})
