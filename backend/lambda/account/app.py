"""
계정 삭제 Lambda 핸들러
DELETE /account - DynamoDB 사용자 데이터 전체 삭제
(Cognito 계정 삭제는 iOS에서 AccessToken으로 직접 호출)
"""
import json
import os

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")


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
    if event["httpMethod"] != "DELETE":
        return _err(405, "Method Not Allowed")

    uid = _user_id(event)

    try:
        _delete_user_data(uid)
        return _ok({"message": "데이터가 삭제되었습니다."})
    except Exception as e:
        return _err(500, str(e))


def _delete_items_with_sort_key(table_name, uid, sort_key):
    """Sort key가 있는 테이블의 userId에 해당하는 모든 항목 삭제"""
    table = dynamodb.Table(table_name)
    last_key = None
    while True:
        kwargs = {"KeyConditionExpression": Key("userId").eq(uid)}
        if last_key:
            kwargs["ExclusiveStartKey"] = last_key
        resp = table.query(**kwargs)
        items = resp.get("Items", [])
        if items:
            with table.batch_writer() as batch:
                for item in items:
                    batch.delete_item(Key={"userId": uid, sort_key: item[sort_key]})
        last_key = resp.get("LastEvaluatedKey")
        if not last_key:
            break


def _delete_user_data(uid):
    # profiles (hash key만 있음)
    dynamodb.Table(os.environ["PROFILES_TABLE"]).delete_item(Key={"userId": uid})
    # device_tokens (hash key만 있음)
    dynamodb.Table(os.environ["DEVICE_TOKENS_TABLE"]).delete_item(Key={"userId": uid})
    # feedings (range key: feedingTime)
    _delete_items_with_sort_key(os.environ["FEEDINGS_TABLE"], uid, "feedingTime")
    # bowels (range key: bowelTime)
    _delete_items_with_sort_key(os.environ["BOWELS_TABLE"], uid, "bowelTime")
    # insights (range key: generatedAt)
    _delete_items_with_sort_key(os.environ["INSIGHTS_TABLE"], uid, "generatedAt")
