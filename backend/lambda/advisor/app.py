"""
AI 어드바이저 Lambda 핸들러
POST /advisor/advice - 최근 7일 수유·배변 기록 분석 후 Bedrock Claude 추천 반환

[보안] Bedrock 호출 실패 시 기본 응답(월령 기반 규칙 추천)으로 대체
[할당량] 유저당 하루 최대 5회 Bedrock 호출. 초과 시 마지막 캐시 결과 조용히 반환
"""
import json
import os
import decimal
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
feedings_table = dynamodb.Table(os.environ["FEEDINGS_TABLE"])
bowels_table = dynamodb.Table(os.environ["BOWELS_TABLE"])
profiles_table = dynamodb.Table(os.environ["PROFILES_TABLE"])
quota_table = dynamodb.Table(os.environ["LLM_QUOTA_TABLE"])

BEDROCK_REGION = os.environ.get("BEDROCK_REGION", "us-east-1")
MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0"
ADVISOR_DAILY_LIMIT = 5

# 월령별 권장 기준 (대한소아과학회 · WHO 가이드라인 참고)
_AGE_RECS = {
    (0, 1):  {"interval_h": 2.5, "amount_ml": 80},
    (1, 3):  {"interval_h": 3.5, "amount_ml": 120},
    (3, 6):  {"interval_h": 3.5, "amount_ml": 150},
    (6, 12): {"interval_h": 4.5, "amount_ml": 200},
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


def _age_months(birth_date_str: str) -> int:
    try:
        birth = datetime.fromisoformat(birth_date_str[:10])
        today = datetime.now(timezone.utc).replace(tzinfo=None)
        months = (today.year - birth.year) * 12 + (today.month - birth.month)
        return max(0, months)
    except Exception:
        return 3  # 파싱 실패 시 3개월로 기본값


def _get_rec(age_months: int) -> dict:
    for (min_age, max_age), rec in _AGE_RECS.items():
        if min_age <= age_months < max_age:
            return rec
    return {"interval_h": 4.5, "amount_ml": 200}


def _default_advice(age_months: int, rec: dict) -> dict:
    return {
        "nextFeedingAdvice": (
            f"현재 월령({age_months}개월) 기준 {rec['interval_h']}시간 간격으로 수유를 권장합니다."
        ),
        "amountAdvice": (
            f"1회 {rec['amount_ml']}ml를 기준으로 아이의 식욕에 따라 조절하세요."
        ),
        "overallOpinion": "기록이 충분히 쌓이면 더 정확한 AI 분석이 가능합니다.",
        "disclaimer": (
            "권장 수유 간격 및 분유량은 대한소아과학회·WHO 가이드라인을 참고한 것으로, "
            "의료적 진단을 대체하지 않습니다."
        ),
    }


def handler(event, context):
    uid = _user_id(event)

    # 프로필 조회 → 월령 계산
    profile = profiles_table.get_item(Key={"userId": uid}).get("Item", {})
    birth_date = profile.get("babyBirthDate", "")
    age_months = _age_months(birth_date)
    rec = _get_rec(age_months)

    # 최근 7일 데이터 조회
    seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()

    feedings = feedings_table.query(
        KeyConditionExpression=Key("userId").eq(uid)
        & Key("feedingTime").gte(seven_days_ago),
        ScanIndexForward=True,
    ).get("Items", [])

    bowels = bowels_table.query(
        KeyConditionExpression=Key("userId").eq(uid)
        & Key("bowelTime").gte(seven_days_ago),
        ScanIndexForward=True,
    ).get("Items", [])

    # 데이터가 전혀 없으면 기본 응답
    if not feedings:
        return _ok(_default_advice(age_months, rec))

    # 일일 할당량 체크 → 초과 시 캐시된 조언 조용히 반환
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    quota_item = quota_table.get_item(Key={"userId": uid, "date": today}).get("Item")
    if quota_item and int(quota_item.get("advisorCount", 0)) >= ADVISOR_DAILY_LIMIT:
        cached = quota_item.get("advisorCache")
        if cached:
            return _ok(json.loads(cached))
        return _ok(_default_advice(age_months, rec))

    # Bedrock 프롬프트 구성
    feedings_text = "\n".join(
        f"- {f['feedingTime']}: {f['amountMl']}ml" for f in feedings[-20:]
    )
    bowels_text = "\n".join(
        f"- {b['bowelTime']}: {b['condition']}" for b in bowels[-20:]
    ) or "기록 없음"

    prompt = f"""당신은 영아 분유 수유 전문 어드바이저입니다.
아래 데이터를 분석하여 한국어로 간결한 추천을 제공하세요.

[아이 정보]
- 현재 월령: {age_months}개월
- 월령별 권장 수유 간격: {rec['interval_h']}시간
- 월령별 1회 권장 분유량: {rec['amount_ml']}ml

[최근 7일 수유 기록]
{feedings_text}

[최근 7일 배변 기록]
{bowels_text}

아래 3가지 항목을 각각 1~2문장으로 작성하고, 반드시 JSON만 반환하세요:
{{
  "nextFeedingAdvice": "다음 수유 시간 조정 추천",
  "amountAdvice": "분유량 조언",
  "overallOpinion": "수유-배변 종합 의견",
  "disclaimer": "권장 수유 간격 및 분유량은 대한소아과학회·WHO 가이드라인을 참고한 것으로, 의료적 진단을 대체하지 않습니다."
}}"""

    try:
        bedrock = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
        resp = bedrock.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 600,
                "messages": [{"role": "user", "content": prompt}],
            }),
        )
        text = json.loads(resp["body"].read())["content"][0]["text"].strip()

        start, end = text.find("{"), text.rfind("}") + 1
        advice = json.loads(text[start:end]) if start >= 0 and end > start else {}

        # 필수 필드 누락 시 기본값으로 보완
        default = _default_advice(age_months, rec)
        for key in default:
            advice.setdefault(key, default[key])

        # 할당량 카운터 증가 + 응답 캐시 저장 (실패해도 응답에 영향 없음)
        try:
            ttl_ts = int((datetime.now(timezone.utc) + timedelta(days=2)).timestamp())
            quota_table.update_item(
                Key={"userId": uid, "date": today},
                UpdateExpression=(
                    "SET advisorCount = if_not_exists(advisorCount, :zero) + :one,"
                    " advisorCache = :cache, #ttl = :ttl"
                ),
                ExpressionAttributeValues={
                    ":zero": 0,
                    ":one": 1,
                    ":cache": json.dumps(advice, ensure_ascii=False),
                    ":ttl": ttl_ts,
                },
                ExpressionAttributeNames={"#ttl": "ttl"},
            )
        except Exception:
            pass

        return _ok(advice)

    except Exception as e:
        print(f"[ERROR] Bedrock call failed: {type(e).__name__}: {e}")
        return _ok(_default_advice(age_months, rec))
