#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_PATHS=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/case-studies"
  "$ROOT_DIR/examples"
  "$ROOT_DIR/docs/portfolio"
  "$ROOT_DIR/assets"
)

echo "Running public-content audit in: $ROOT_DIR"

python3 - "$ROOT_DIR" "${SCAN_PATHS[@]}" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
scan_paths = [Path(path) for path in sys.argv[2:]]

patterns = [
    r"BEGIN PRIVATE KEY",
    r"AccountKey=",
    r"SharedAccessSignature=",
    r"DefaultEndpointsProtocol=",
    r"EndpointSuffix=",
    r"Password=",
    r"User ID=",
    r"ClientSecret",
    r"TenantId",
    r"WorkspaceDefaultStorage",
    r"WorkspaceDefaultSqlServer",
    r"jdbc:sqlserver://",
    r"sql\.azuresynapse\.net",
    r"sharepoint\.com",
    r"workspaceId",
    r"datasetId",
    r"reportId",
    r"subscriptionId",
    r"/Users/",
    r"@enablecv",
    r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
]

ignored_suffixes = {".gif", ".jpeg", ".jpg", ".pdf", ".png", ".webp"}
compiled = [(pattern, re.compile(pattern, re.IGNORECASE)) for pattern in patterns]
matches: list[tuple[str, Path, int, str]] = []


def iter_files(path: Path):
    if path.is_file():
        yield path
        return
    if path.is_dir():
        for child in path.rglob("*"):
            if child.is_file():
                yield child


for scan_path in scan_paths:
    for file_path in iter_files(scan_path):
        if file_path.suffix.lower() in ignored_suffixes:
            continue
        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(text.splitlines(), start=1):
            for label, regex in compiled:
                if regex.search(line):
                    matches.append((label, file_path, line_number, line.strip()))

if matches:
    for label, file_path, line_number, line in matches:
        relative = file_path.relative_to(root)
        print(f"Potential match for pattern: {label}")
        print(f"{relative}:{line_number}: {line}")
    print("Review the matches above before publishing.")
    raise SystemExit(1)

print("No matches found.")
PY
