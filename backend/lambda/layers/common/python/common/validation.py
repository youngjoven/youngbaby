import json
import re
from datetime import datetime, timezone

_ISO8601_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$"
)


def validate_iso8601(value, field_name="timestamp"):
    """ISO 8601 형식 검증. 유효하면 None, 아니면 에러 메시지 반환."""
    if not value or not isinstance(value, str):
        return f"{field_name} is required"
    if not _ISO8601_RE.match(value):
        return f"{field_name} must be ISO 8601 format (e.g. 2024-01-15T09:00:00Z)"
    return None


def validate_range(value, field_name, min_val, max_val):
    """숫자 범위 검증. 유효하면 None, 아니면 에러 메시지 반환."""
    if value is None:
        return f"{field_name} is required"
    try:
        num = int(value)
    except (TypeError, ValueError):
        return f"{field_name} must be a number"
    if num < min_val or num > max_val:
        return f"{field_name} must be between {min_val} and {max_val}"
    return None


def validate_string_length(value, field_name, max_len=200):
    """문자열 길이 검증. 유효하면 None, 아니면 에러 메시지 반환."""
    if not value or not isinstance(value, str):
        return f"{field_name} is required"
    if len(value) > max_len:
        return f"{field_name} must be at most {max_len} characters"
    return None


def parse_json_body(event):
    """이벤트에서 JSON body를 안전하게 파싱. 실패 시 None 반환."""
    try:
        return json.loads(event.get("body") or "{}")
    except (json.JSONDecodeError, TypeError):
        return None
