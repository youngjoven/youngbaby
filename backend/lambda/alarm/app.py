"""
알람 예약 Lambda 핸들러
POST /alarm/schedule - 다음 수유 시각에 EventBridge Scheduler로 알람 예약
"""
import json
import os
from datetime import datetime, timezone, timedelta

import boto3
from common import ok, err, user_id
from common.validation import parse_json_body

scheduler = boto3.client("scheduler")

SCHEDULER_ROLE_ARN = os.environ["SCHEDULER_ROLE_ARN"]
ALARM_DELIVERY_ARN = os.environ["ALARM_DELIVERY_ARN"]


def handler(event, context):
    uid = user_id(event)
    body = parse_json_body(event)
    if body is None:
        return err(400, "Invalid JSON body")

    next_feeding_time = body.get("nextFeedingTime")
    if not next_feeding_time:
        return err(400, "nextFeedingTime is required")

    try:
        scheduled_dt = datetime.fromisoformat(next_feeding_time.replace("Z", "+00:00"))
    except ValueError:
        return err(400, "nextFeedingTime must be ISO 8601 format")

    now = datetime.now(timezone.utc)
    if scheduled_dt <= now + timedelta(minutes=1):
        return ok({"message": "Scheduled time is in the past, skipped"})

    safe_uid = uid.replace("-", "")[:20]
    schedule_name = f"youngbaby-alarm-{safe_uid}-{int(scheduled_dt.timestamp())}"
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
            ActionAfterCompletion="DELETE",
        )
    except scheduler.exceptions.ConflictException:
        pass
    except Exception as e:
        print(f"[ERROR] Schedule creation failed: {type(e).__name__}: {e}")
        return err(500, "Failed to schedule alarm")

    return ok({"message": "Alarm scheduled", "scheduledAt": next_feeding_time})
