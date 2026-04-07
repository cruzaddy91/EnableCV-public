#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_PATHS=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/case-studies"
  "$ROOT_DIR/examples"
  "$ROOT_DIR/assets"
)

echo "Running public-content audit in: $ROOT_DIR"

patterns=(
  "BEGIN PRIVATE KEY"
  "AccountKey="
  "SharedAccessSignature="
  "DefaultEndpointsProtocol="
  "EndpointSuffix="
  "Password="
  "User ID="
  "ClientSecret"
  "TenantId"
  "WorkspaceDefaultStorage"
  "WorkspaceDefaultSqlServer"
  "jdbc:sqlserver://"
  "@enablecv"
)

exit_code=0

for pattern in "${patterns[@]}"; do
  if rg -n -i \
    --glob '!*.png' \
    --glob '!*.jpg' \
    --glob '!*.jpeg' \
    --glob '!*.gif' \
    "$pattern" "${SCAN_PATHS[@]}" >/dev/null; then
    echo "Potential match for pattern: $pattern"
    rg -n -i \
      --glob '!*.png' \
      --glob '!*.jpg' \
      --glob '!*.jpeg' \
      --glob '!*.gif' \
      "$pattern" "${SCAN_PATHS[@]}" || true
    exit_code=1
  fi
done

if [[ $exit_code -eq 0 ]]; then
  echo "No matches found."
else
  echo "Review the matches above before publishing."
fi

exit "$exit_code"
