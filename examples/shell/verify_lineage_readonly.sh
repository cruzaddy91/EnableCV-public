#!/usr/bin/env bash
################################################################################
# Verify reporting-lineage integrity with read-only SQL checks.
#
# Purpose:
#   Confirm that expected reporting views exist and still point to approved
#   upstream schemas before report handoff, release validation, or troubleshooting.
#
# Requirements:
#   - sqlcmd available on PATH
#   - DB_SERVER set
#   - DB_NAME set
#
# Optional:
#   - REPORTING_VIEWS comma-separated list, default: vw_orders,vw_order_lines
#
# Example:
#   DB_SERVER=my-server.example.net \
#   DB_NAME=analytics \
#   REPORTING_VIEWS=vw_orders,vw_order_lines,vw_customers \
#   ./verify_lineage_readonly.sh
################################################################################

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: required environment variable missing: $name" >&2
    exit 1
  fi
}

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $name" >&2
    exit 1
  fi
}

quote_csv_for_sql() {
  local csv="$1"
  local result=""
  IFS=',' read -ra items <<< "$csv"
  for raw_item in "${items[@]}"; do
    local item
    item="$(printf '%s' "$raw_item" | xargs)"
    [[ -z "$item" ]] && continue
    item="${item//\'/\'\'}"
    if [[ -n "$result" ]]; then
      result+=","
    fi
    result+="'$item'"
  done
  printf '%s' "$result"
}

require_env "DB_SERVER"
require_env "DB_NAME"
require_cmd "sqlcmd"

REPORTING_SCHEMA="${REPORTING_SCHEMA:-rpt}"
APPROVED_SOURCE_SCHEMAS="${APPROVED_SOURCE_SCHEMAS:-stg,core,dim}"
REPORTING_VIEWS="${REPORTING_VIEWS:-vw_orders,vw_order_lines}"

view_list="$(quote_csv_for_sql "$REPORTING_VIEWS")"
source_schema_list="$(quote_csv_for_sql "$APPROVED_SOURCE_SCHEMAS")"

if [[ -z "$view_list" ]]; then
  echo "ERROR: REPORTING_VIEWS did not contain any view names." >&2
  exit 1
fi

read -r -d '' SQL_QUERY <<EOF || true
WITH expected_views AS (
    SELECT value AS view_name
    FROM STRING_SPLIT(REPLACE('$REPORTING_VIEWS', ' ', ''), ',')
),
existing_views AS (
    SELECT s.name AS schema_name, v.name AS view_name
    FROM sys.views v
    JOIN sys.schemas s ON v.schema_id = s.schema_id
    WHERE s.name = '$REPORTING_SCHEMA'
      AND v.name IN ($view_list)
),
view_dependencies AS (
    SELECT
        OBJECT_SCHEMA_NAME(d.referencing_id) AS referencing_schema,
        OBJECT_NAME(d.referencing_id) AS referencing_object,
        COALESCE(d.referenced_schema_name, '') AS referenced_schema,
        COALESCE(d.referenced_entity_name, '') AS referenced_object
    FROM sys.sql_expression_dependencies d
    WHERE OBJECT_SCHEMA_NAME(d.referencing_id) = '$REPORTING_SCHEMA'
      AND OBJECT_NAME(d.referencing_id) IN ($view_list)
)
SELECT
    ev.view_name,
    CASE WHEN xv.view_name IS NULL THEN 'MISSING' ELSE 'FOUND' END AS availability_status
FROM expected_views ev
LEFT JOIN existing_views xv
  ON xv.view_name = ev.view_name
ORDER BY ev.view_name;

SELECT
    referencing_schema,
    referencing_object,
    referenced_schema,
    referenced_object,
    CASE
        WHEN referenced_schema IN ($source_schema_list) THEN 'APPROVED_SOURCE'
        WHEN referenced_schema = '' THEN 'UNRESOLVED_OR_EXTERNAL'
        ELSE 'REVIEW_SOURCE'
    END AS lineage_status
FROM view_dependencies
ORDER BY referencing_object, referenced_schema, referenced_object;
EOF

sqlcmd \
  -S "$DB_SERVER" \
  -d "$DB_NAME" \
  -W \
  -s "," \
  -Q "$SQL_QUERY"
