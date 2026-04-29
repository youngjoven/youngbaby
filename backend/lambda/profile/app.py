"""
프로필 Lambda 핸들러
GET /profile  - 프로필 조회
PUT /profile  - 프로필 생성/수정
"""
import os
from datetime import datetime, timezone

import boto3
from common import ok, err, user_id
from common.validation import parse_json_body, validate_string_length

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["PROFILES_TABLE"])


def handler(event, context):
    method = event["httpMethod"]
    uid = user_id(event)

    if method == "GET":
        return _get(uid)
    if method == "PUT":
        return _put(event, uid)
    return err(405, "Method Not Allowed")


def _get(uid):
    result = table.get_item(Key={"userId": uid})
    item = result.get("Item")
    if not item:
        return err(404, "Profile not found")
    return ok(item)


def _put(event, uid):
    body = parse_json_body(event)
    if body is None:
        return err(400, "Invalid JSON body")

    baby_name = body.get("babyName", "")
    baby_birth_date = body.get("babyBirthDate", "")
    mother_name = body.get("motherName", "")

    if e := validate_string_length(baby_name, "babyName", 50):
        return err(400, e)
    if not baby_birth_date:
        return err(400, "babyBirthDate is required")
    if mother_name and (e := validate_string_length(mother_name, "motherName", 50)):
        return err(400, e)

    item = {
        "userId": uid,
        "babyName": baby_name,
        "babyBirthDate": baby_birth_date,
        "motherName": mother_name,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
    table.put_item(Item=item)
    return ok(item)
