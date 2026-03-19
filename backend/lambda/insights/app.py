"""
데이터 인사이트 Lambda 핸들러
GET /insights - 주간 인사이트 목록 조회

동작:
1. 최근 7일 이내 생성된 인사이트가 있으면 그대로 반환
2. 없으면 최근 4주 데이터를 Bedrock으로 분석 → 인사이트 생성 → DynamoDB 저장 후 반환
3. 최소 3일 기록이 없으면 빈 배열 반환
"""
import json
import os
import decimal
import uuid
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
feedings_table = dynamodb.Table(os.environ["FEEDINGS_TABLE"])
bowels_table = dynamodb.Table(os.environ["BOWELS_TABLE"])
profiles_table = dynamodb.Table(os.environ["PROFILES_TABLE"])
insights_table = dynamodb.Table(os.environ["INSIGHTS_TABLE"])

BEDROCK_REGION = os.environ.get("BEDROCK_REGION", "us-east-1")
MODEL_ID = "anthropic.claude-sonnet-4-20250514-v1:0"

VALID_INSIGHT_TYPES = {
    "amount_change",
    "interval_change",
    "bowel_pattern",
    "age_comparison",
    "feeding_bowel",
}


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


def _user_id(event):
    return event["requestContext"]["authorizer"]["claims"]["sub"]


def handler(event, context):
    uid = _user_id(event)

    # 최근 7일 이내 인사이트가 있으면 기존 것 반환
    seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
    existing = insights_table.query(
        KeyConditionExpression=Key("userId").eq(uid)
        & Key("generatedAt").gte(seven_days_ago),
        ScanIndexForward=False,
        Limit=10,
    ).get("Items", [])

    if existing:
        return _ok(existing)

    # 최근 4주 수유 기록 조회
    four_weeks_ago = (datetime.now(timezone.utc) - timedelta(weeks=4)).isoformat()

    feedings = feedings_table.query(
        KeyConditionExpression=Key("userId").eq(uid)
        & Key("feedingTime").gte(four_weeks_ago),
        ScanIndexForward=True,
    ).get("Items", [])

    # 최소 3일 기록 필요
    if feedings:
        dates = {f["feedingTime"][:10] for f in feedings}
        if len(dates) < 3:
            return _ok([])
    else:
        return _ok([])

    bowels = bowels_table.query(
        KeyConditionExpression=Key("userId").eq(uid)
        & Key("bowelTime").gte(four_weeks_ago),
        ScanIndexForward=True,
    ).get("Items", [])

    profile = profiles_table.get_item(Key={"userId": uid}).get("Item", {})
    birth_date = profile.get("babyBirthDate", "정보 없음")

    feedings_text = "\n".join(
        f"- {f['feedingTime']}: {f['amountMl']}ml" for f in feedings[-50:]
    )
    bowels_text = "\n".join(
        f"- {b['bowelTime']}: {b['condition']}" for b in bowels[-50:]
    ) or "기록 없음"

    prompt = f"""당신은 영아 건강 데이터 분석 전문가입니다.
아래 최근 4주 수유·배변 데이터를 분석하여 인사이트를 한국어로 생성하세요.

[아이 생년월일] {birth_date}

[최근 4주 수유 기록]
{feedings_text}

[최근 4주 배변 기록]
{bowels_text}

감지된 인사이트만 JSON 배열로 반환하세요 (없으면 빈 배열 []):
[
  {{
    "insightType": "<유형>",
    "content": "<인사이트 내용 1~2문장>"
  }}
]

인사이트 유형 (insightType):
- amount_change: 분유량 변화 감지 (이번 주 평균 vs 지난주 ±15% 이상)
- interval_change: 수유 간격 변화 (평균 30분 이상 변화)
- bowel_pattern: 배변 이상 패턴 (최근 3일 연속 묽음/단단함)
- age_comparison: 월령별 권장량 비교 (하루 평균 vs 권장량 ±20%)
- feeding_bowel: 수유-배변 연관 패턴"""

    insights_list = []
    try:
        bedrock = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
        resp = bedrock.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [{"role": "user", "content": prompt}],
            }),
        )
        text = json.loads(resp["body"].read())["content"][0]["text"].strip()

        start, end = text.find("["), text.rfind("]") + 1
        if start >= 0 and end > start:
            parsed = json.loads(text[start:end])
            # 유효한 insightType만 허용
            insights_list = [
                i for i in parsed
                if isinstance(i, dict) and i.get("insightType") in VALID_INSIGHT_TYPES
            ][:5]
    except Exception:
        pass

    # DynamoDB 저장
    now = datetime.now(timezone.utc).isoformat()
    saved = []
    for idx, insight in enumerate(insights_list):
        item = {
            "userId": uid,
            "generatedAt": f"{now}_{idx:02d}",  # sort key 고유성 보장
            "id": str(uuid.uuid4()),
            "insightType": insight["insightType"],
            "content": insight.get("content", ""),
        }
        insights_table.put_item(Item=item)
        saved.append(item)

    return _ok(saved)
