#!/usr/bin/env python3
"""
Read-only Power BI REST discovery helper.

This public-safe example shows the operating pattern for inventorying BI
workspaces, reports, datasets, datasources, and refresh history without storing
secrets or writing to the service. It masks IDs by default so command output is
safer to paste into tickets or handoff notes.

Auth:
  export PBI_TOKEN="$(az account get-access-token \
    --resource https://analysis.windows.net/powerbi/api \
    --query accessToken -o tsv)"
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


BASE_URL = "https://api.powerbi.com/v1.0/myorg"


def get_token() -> str:
    token = os.environ.get("PBI_TOKEN", "").strip()
    if not token:
        raise SystemExit("Set PBI_TOKEN before running this read-only discovery helper.")
    return token


def request_json(method: str, url: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
    headers = {"Authorization": f"Bearer {get_token()}"}
    payload = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        payload = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(url, headers=headers, data=payload, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Power BI request failed: HTTP {exc.code}: {detail[:1000]}") from exc

    return json.loads(raw) if raw else {}


def mask_identifier(value: Any) -> Any:
    if not isinstance(value, str) or len(value) < 12:
        return value
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:10]
    return f"masked-{digest}"


def sanitize_record(record: dict[str, Any], mask_ids: bool) -> dict[str, Any]:
    if not mask_ids:
        return record
    sanitized: dict[str, Any] = {}
    for key, value in record.items():
        if key.lower().endswith("id") or key.lower() == "id":
            sanitized[key] = mask_identifier(value)
        elif isinstance(value, dict):
            sanitized[key] = sanitize_record(value, mask_ids=True)
        elif isinstance(value, list):
            sanitized[key] = [
                sanitize_record(item, mask_ids=True) if isinstance(item, dict) else item
                for item in value
            ]
        else:
            sanitized[key] = value
    return sanitized


def list_workspaces(top: int) -> list[dict[str, Any]]:
    url = f"{BASE_URL}/groups?{urllib.parse.urlencode({'$top': top})}"
    return request_json("GET", url).get("value", [])


def list_reports(workspace_id: str, top: int) -> list[dict[str, Any]]:
    url = f"{BASE_URL}/groups/{workspace_id}/reports?{urllib.parse.urlencode({'$top': top})}"
    return request_json("GET", url).get("value", [])


def list_datasets(workspace_id: str, top: int) -> list[dict[str, Any]]:
    url = f"{BASE_URL}/groups/{workspace_id}/datasets?{urllib.parse.urlencode({'$top': top})}"
    return request_json("GET", url).get("value", [])


def dataset_refreshes(workspace_id: str, dataset_id: str, top: int) -> list[dict[str, Any]]:
    url = f"{BASE_URL}/groups/{workspace_id}/datasets/{dataset_id}/refreshes?{urllib.parse.urlencode({'$top': top})}"
    return request_json("GET", url).get("value", [])


def dataset_datasources(workspace_id: str, dataset_id: str) -> list[dict[str, Any]]:
    url = f"{BASE_URL}/groups/{workspace_id}/datasets/{dataset_id}/datasources"
    return request_json("GET", url).get("value", [])


def print_json(data: Any, mask_ids: bool) -> None:
    if isinstance(data, list):
        data = [sanitize_record(item, mask_ids) if isinstance(item, dict) else item for item in data]
    elif isinstance(data, dict):
        data = sanitize_record(data, mask_ids)
    print(json.dumps(data, indent=2, sort_keys=True, default=str))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="powerbi_api_discovery.py")
    parser.add_argument("--workspace-id", help="Workspace ID for report or dataset discovery")
    parser.add_argument("--dataset-id", help="Dataset ID for refresh or datasource discovery")
    parser.add_argument("--top", type=int, default=25, help="Maximum rows to request")
    parser.add_argument("--show-raw-ids", action="store_true", help="Print raw IDs instead of masked IDs")

    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("workspaces")
    subcommands.add_parser("reports")
    subcommands.add_parser("datasets")
    subcommands.add_parser("refreshes")
    subcommands.add_parser("datasources")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.command in {"reports", "datasets", "refreshes", "datasources"} and not args.workspace_id:
        raise SystemExit("--workspace-id is required for this command.")
    if args.command in {"refreshes", "datasources"} and not args.dataset_id:
        raise SystemExit("--dataset-id is required for this command.")

    if args.command == "workspaces":
        result = list_workspaces(args.top)
    elif args.command == "reports":
        result = list_reports(args.workspace_id, args.top)
    elif args.command == "datasets":
        result = list_datasets(args.workspace_id, args.top)
    elif args.command == "refreshes":
        result = dataset_refreshes(args.workspace_id, args.dataset_id, args.top)
    else:
        result = dataset_datasources(args.workspace_id, args.dataset_id)

    print_json(result, mask_ids=not args.show_raw_ids)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
