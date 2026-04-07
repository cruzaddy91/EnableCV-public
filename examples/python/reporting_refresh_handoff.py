#!/usr/bin/env python3
"""
Build a reporting refresh handoff checklist from a generic trigger definition.

This script is intentionally public-safe. It takes a small JSON document that
describes how an upstream pipeline runs, then computes recommended BI refresh
times and prints the remaining operator handoff steps.

Example trigger JSON:

{
  "name": "daily-reporting-trigger",
  "type": "ScheduleTrigger",
  "runtimeState": "Started",
  "recurrence": {
    "frequency": "Hour",
    "interval": 6,
    "startTime": "2026-01-01T02:00:00",
    "timeZone": "Mountain Standard Time"
  }
}
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo


WINDOWS_TZ_TO_IANA = {
    "Central Standard Time": "America/Chicago",
    "Mountain Standard Time": "America/Denver",
    "Eastern Standard Time": "America/New_York",
    "Pacific Standard Time": "America/Los_Angeles",
    "UTC": "UTC",
}


@dataclass(frozen=True)
class DailyTime:
    hour: int
    minute: int


def resolve_timezone(name: str) -> ZoneInfo:
    iana_name = WINDOWS_TZ_TO_IANA.get(name)
    if not iana_name:
        supported = ", ".join(sorted(WINDOWS_TZ_TO_IANA))
        raise SystemExit(f"Unsupported timezone '{name}'. Supported values: {supported}")
    return ZoneInfo(iana_name)


def load_trigger(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Trigger file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Failed to parse JSON in {path}: {exc}") from exc


def parse_trigger_start(start_raw: str, timezone_name: str) -> datetime:
    tz = resolve_timezone(timezone_name)
    return datetime.fromisoformat(start_raw).replace(tzinfo=tz)


def derive_daily_times(trigger: dict) -> tuple[list[DailyTime], str]:
    recurrence = (trigger.get("recurrence") or {})
    frequency = recurrence.get("frequency")
    interval = recurrence.get("interval")
    schedule = recurrence.get("schedule") or {}
    start_time = recurrence.get("startTime")
    timezone_name = recurrence.get("timeZone", "UTC")

    if schedule.get("hours") and schedule.get("minutes"):
        minutes = schedule["minutes"]
        if len(minutes) != 1:
            raise SystemExit("Only one minute value per schedule is supported.")
        return (
            [DailyTime(hour=hour, minute=minutes[0]) for hour in sorted(schedule["hours"])],
            timezone_name,
        )

    if frequency == "Hour" and isinstance(interval, int) and interval > 0 and start_time:
        start_local = parse_trigger_start(start_time, timezone_name)
        seen: set[tuple[int, int]] = set()
        times: list[DailyTime] = []
        cursor = start_local
        while True:
            key = (cursor.hour, cursor.minute)
            if key in seen:
                break
            seen.add(key)
            times.append(DailyTime(hour=cursor.hour, minute=cursor.minute))
            cursor = cursor + timedelta(hours=interval)
        return sorted(times, key=lambda item: (item.hour, item.minute)), timezone_name

    raise SystemExit(
        "Unsupported recurrence pattern. Supported today: explicit scheduled "
        "hours/minutes or simple hourly recurrence."
    )


def shift_times(
    times: list[DailyTime],
    delay_minutes: int,
    from_timezone_name: str,
    target_timezone_name: str,
) -> list[DailyTime]:
    from_timezone = resolve_timezone(from_timezone_name)
    target_timezone = resolve_timezone(target_timezone_name)
    anchor = datetime.now(from_timezone)
    shifted: list[DailyTime] = []

    for item in times:
        source_dt = anchor.replace(
            hour=item.hour,
            minute=item.minute,
            second=0,
            microsecond=0,
        ) + timedelta(minutes=delay_minutes)
        target_dt = source_dt.astimezone(target_timezone)
        shifted.append(DailyTime(hour=target_dt.hour, minute=target_dt.minute))

    return sorted(shifted, key=lambda item: (item.hour, item.minute))


def format_time(item: DailyTime) -> str:
    return f"{item.hour:02d}:{item.minute:02d}"


def print_checklist(
    project_name: str,
    trigger: dict,
    trigger_times: list[DailyTime],
    refresh_times: list[DailyTime],
    trigger_timezone_name: str,
    refresh_timezone_name: str,
    delay_minutes: int,
) -> None:
    recurrence = trigger.get("recurrence") or {}
    print(f"Reporting refresh handoff: {project_name}")
    print(f"Trigger: {trigger.get('name', 'unknown-trigger')}")
    print(f"Trigger type: {trigger.get('type', 'unknown-type')}")
    print(f"Trigger state: {trigger.get('runtimeState', 'unknown-state')}")
    print(f"Trigger timezone: {trigger_timezone_name}")
    if recurrence.get("startTime"):
        print(f"Trigger start time: {recurrence['startTime']}")
    print(f"Delay after trigger: {delay_minutes} minutes")
    print(f"BI refresh timezone: {refresh_timezone_name}")
    print()
    print("Trigger fire times:")
    for item in trigger_times:
        print(f"- {format_time(item)} {trigger_timezone_name}")
    print()
    print("Recommended BI refresh times:")
    for item in refresh_times:
        print(f"- {format_time(item)} {refresh_timezone_name}")
    print()
    print("Operator handoff checklist:")
    print("- Confirm the report or semantic model points to the intended serving object.")
    print("- Validate that upstream refresh completed successfully before enabling the schedule.")
    print("- Set the BI refresh timezone and schedule to match the recommended times above.")
    print("- Validate credentials, gateway status, and refresh history before signoff.")
    print("- Run one manual refresh after publish or cutover and confirm success.")
    print("- Record the schedule, owner, and serving object in the project runbook.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="reporting_refresh_handoff.py")
    parser.add_argument("--project-name", required=True, help="Reporting project label")
    parser.add_argument("--trigger-file", required=True, type=Path, help="Path to trigger JSON")
    parser.add_argument(
        "--delay-minutes",
        type=int,
        default=90,
        help="Delay between upstream trigger time and BI refresh",
    )
    parser.add_argument(
        "--refresh-timezone",
        default="UTC",
        help="Target BI schedule timezone",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    trigger = load_trigger(args.trigger_file)
    trigger_times, trigger_timezone_name = derive_daily_times(trigger)
    refresh_times = shift_times(
        trigger_times,
        args.delay_minutes,
        trigger_timezone_name,
        args.refresh_timezone,
    )
    print_checklist(
        args.project_name,
        trigger,
        trigger_times,
        refresh_times,
        trigger_timezone_name,
        args.refresh_timezone,
        args.delay_minutes,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
