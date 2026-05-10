#!/usr/bin/env python3
"""
Build a public-safe read-only discovery report from sanitized JSON input.

The private pattern behind this example captured discovery results, query
metadata, and operator notes in a repeatable HTML handoff. This version keeps
the reporting shape while using neutral field names and caller-supplied input.

Example:
  python readonly_discovery_report_builder.py \
    --input sample_discovery.json \
    --output discovery-report.html \
    --title "Reporting Readiness Discovery"
"""

from __future__ import annotations

import argparse
import html
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Input file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Input file is not valid JSON: {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise SystemExit("Input JSON must be an object.")
    return data


def as_list(value: Any) -> list[dict[str, Any]]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise SystemExit("Expected a list of objects in the discovery input.")
    rows: list[dict[str, Any]] = []
    for item in value:
        if not isinstance(item, dict):
            raise SystemExit("Each discovery row must be an object.")
        rows.append(item)
    return rows


def cell(value: Any) -> str:
    if value is None:
        return ""
    return html.escape(str(value))


def render_table(rows: list[dict[str, Any]], empty_message: str) -> str:
    if not rows:
        return f"<p class=\"muted\">{html.escape(empty_message)}</p>"

    columns = sorted({key for row in rows for key in row})
    header = "".join(f"<th>{cell(column)}</th>" for column in columns)
    body = []
    for row in rows:
        body.append("<tr>" + "".join(f"<td>{cell(row.get(column))}</td>" for column in columns) + "</tr>")

    return f"""
    <table>
      <thead><tr>{header}</tr></thead>
      <tbody>{''.join(body)}</tbody>
    </table>
    """


def render_html(title: str, data: dict[str, Any]) -> str:
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    summary = data.get("summary") or {}
    assets = as_list(data.get("assets"))
    checks = as_list(data.get("checks"))
    query_audit = as_list(data.get("query_audit"))
    notes = data.get("notes") or []
    if not isinstance(summary, dict):
        raise SystemExit("summary must be an object when provided.")
    if not isinstance(notes, list):
        raise SystemExit("notes must be a list when provided.")

    note_items = "".join(f"<li>{cell(note)}</li>" for note in notes) or "<li>No notes supplied.</li>"
    kpis = [
        ("Assets reviewed", len(assets)),
        ("Checks captured", len(checks)),
        ("Queries audited", len(query_audit)),
        ("Generated", generated_at),
    ]

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{cell(title)}</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 32px; color: #1f2937; }}
    h1, h2 {{ color: #1f3a5f; }}
    .muted {{ color: #5f6b7a; }}
    .grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }}
    .card {{ border: 1px solid #d8dee9; border-radius: 8px; padding: 14px; background: #f8fafc; }}
    .value {{ font-size: 1.4rem; font-weight: 700; margin-top: 6px; }}
    table {{ border-collapse: collapse; width: 100%; margin: 12px 0 24px; }}
    th, td {{ border: 1px solid #d8dee9; padding: 8px; text-align: left; vertical-align: top; }}
    th {{ background: #eef2f8; }}
    section {{ margin-top: 28px; }}
  </style>
</head>
<body>
  <h1>{cell(title)}</h1>
  <p class="muted">Public-safe example generated from sanitized discovery input.</p>

  <section class="grid">
    {''.join(f'<div class="card"><div>{cell(label)}</div><div class="value">{cell(value)}</div></div>' for label, value in kpis)}
  </section>

  <section>
    <h2>Summary</h2>
    {render_table([summary] if summary else [], "No summary supplied.")}
  </section>

  <section>
    <h2>Assets Reviewed</h2>
    {render_table(assets, "No assets supplied.")}
  </section>

  <section>
    <h2>Readiness Checks</h2>
    {render_table(checks, "No checks supplied.")}
  </section>

  <section>
    <h2>Query Audit</h2>
    {render_table(query_audit, "No query audit supplied.")}
  </section>

  <section>
    <h2>Operator Notes</h2>
    <ul>{note_items}</ul>
  </section>
</body>
</html>
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="readonly_discovery_report_builder.py")
    parser.add_argument("--input", required=True, type=Path, help="Sanitized discovery JSON")
    parser.add_argument("--output", required=True, type=Path, help="HTML report output path")
    parser.add_argument("--title", default="Read-Only Discovery Report", help="Report title")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    data = load_json(args.input)
    args.output.write_text(render_html(args.title, data), encoding="utf-8")
    print(f"Wrote report: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
