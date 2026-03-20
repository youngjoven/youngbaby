"""
알람 예약 Lambda 핸들러
POST /alarm/schedule - 다음 수유 시각에 EventBridge Scheduler로 알람 예약

요청 바디:
  {
    "nextFeedingTime": "2024-01-15T09:00:00Z",   # ISO 8601 UTC
    "userId": "cognito-sub-id"                     # (선택) 명시적 userId
  }

동작:
  EventBridge Scheduler one-time schedule 생성 →
  지정된 시각에 AlarmDeliveryFunction 호출 →
  SNS → APNs → 기기 푸시 알림
"""
import json
import os
from datetime import datetime, timezone, timedelta

import boto3

scheduler = boto3.client("scheduler")

SCHEDULER_ROLE_ARN = os.environ["SCHEDULER_ROLE_ARN"]
ALARM_DELIVERY_ARN = os.environ["ALARM_DELIVERY_ARN"]


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
    next_feeding_time = body.get("nextFeedingTime")

    if not next_feeding_time:
        return _err(400, "nextFeedingTime is required")

    # 과거 시각이면 무시
    try:
        scheduled_dt = datetime.fromisoformat(next_feeding_time.replace("Z", "+00:00"))
    except ValueError:
        return _err(400, "nextFeedingTime must be ISO 8601 format")

    now = datetime.now(timezone.utc)
    if scheduled_dt <= now + timedelta(minutes=1):
        return _ok({"message": "Scheduled time is in the past, skipped"})

    # EventBridge Scheduler 스케줄 이름 (userId + 타임스탬프로 고유성 보장)
    safe_uid = uid.replace("-", "")[:20]
    schedule_name = f"youngbaby-alarm-{safe_uid}-{int(scheduled_dt.timestamp())}"

    # at() 표현식: 한 번만 실행
    schedule_expr = f"at({scheduled_dt.strftime('%Y-%m-%dT%H:%M:%S')})"

    payload = json.dumps({"userId": uid, "nextFeedingTime": next_feeding_time})

    try:
        scheduler.create_schedule(
            Name=schedule_name,
            ScheduleExpression=schedule_expr,
            ScheduleExpressionTimezone="UTC",
            FlexibleTimeWindow={"Mode": "OFF"},
            Target={
                "Arn": ALARM_DELIVERY_ARN,
                "RoleArn": SCHEDULER_ROLE_ARN,
                "Input": payload,
            },
            ActionAfterCompletion="DELETE",  # 실행 후 스케줄 자동 삭제
        )
    except scheduler.exceptions.ConflictException:
        # 이미 동일 스케줄 존재 → 무시
        pass
    except Exception as e:
        return _err(500, f"Failed to schedule alarm: {str(e)}")

    return _ok({"message": "Alarm scheduled", "scheduledAt": next_feeding_time})
