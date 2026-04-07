#!/usr/bin/env bash
################################################################################
# Validate reporting passthrough views in a SQL serving layer.
#
# Purpose:
#   Run read-only parity checks between operational source tables and their
#   reporting-facing views before handoff, cutover, or troubleshooting.
#
# Requirements:
#   - sqlcmd available on PATH
#   - DB_SERVER set
#   - DB_NAME set
#
# Example:
#   DB_SERVER=my-server.example.net \
#   DB_NAME=analytics \
#   ./validate_reporting_views.sh
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

require_env "DB_SERVER"
require_env "DB_NAME"
require_cmd "sqlcmd"

read -r -d '' SQL_QUERY <<'EOF' || true
WITH pairs(source_schema, source_table, view_schema, view_name) AS (
    SELECT 'ops' AS source_schema, 'orders' AS source_table, 'rpt' AS view_schema, 'vw_orders_raw' AS view_name
    UNION ALL SELECT 'ops', 'order_lines', 'rpt', 'vw_order_lines_raw'
    UNION ALL SELECT 'ops', 'customers', 'rpt', 'vw_customers_raw'
),
source_counts AS (
    SELECT 'ops.orders' AS source_name, COUNT(*) AS row_count FROM ops.orders
    UNION ALL SELECT 'ops.order_lines', COUNT(*) FROM ops.order_lines
    UNION ALL SELECT 'ops.customers', COUNT(*) FROM ops.customers
),
view_counts AS (
    SELECT 'rpt.vw_orders_raw' AS view_name, COUNT(*) AS row_count FROM rpt.vw_orders_raw
    UNION ALL SELECT 'rpt.vw_order_lines_raw', COUNT(*) FROM rpt.vw_order_lines_raw
    UNION ALL SELECT 'rpt.vw_customers_raw', COUNT(*) FROM rpt.vw_customers_raw
),
row_parity AS (
    SELECT
        p.source_table,
        p.view_name,
        sc.row_count AS source_row_count,
        vc.row_count AS view_row_count,
        CASE WHEN sc.row_count = vc.row_count THEN 'MATCH' ELSE 'DIFF' END AS row_status
    FROM pairs p
    JOIN source_counts sc
      ON sc.source_name = CONCAT(p.source_schema, '.', p.source_table)
    JOIN view_counts vc
      ON vc.view_name = CONCAT(p.view_schema, '.', p.view_name)
),
source_columns AS (
    SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'ops' AND TABLE_NAME IN ('orders', 'order_lines', 'customers')
),
view_columns AS (
    SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'rpt' AND TABLE_NAME IN ('vw_orders_raw', 'vw_order_lines_raw', 'vw_customers_raw')
),
schema_parity AS (
    SELECT
        p.source_table,
        p.view_name,
        COUNT(*) AS compared_columns,
        SUM(CASE WHEN sc.COLUMN_NAME = vc.COLUMN_NAME THEN 1 ELSE 0 END) AS name_matches,
        SUM(CASE WHEN sc.ORDINAL_POSITION = vc.ORDINAL_POSITION THEN 1 ELSE 0 END) AS ordinal_matches,
        SUM(CASE WHEN sc.DATA_TYPE = vc.DATA_TYPE THEN 1 ELSE 0 END) AS type_matches,
        SUM(CASE WHEN sc.IS_NULLABLE = vc.IS_NULLABLE THEN 1 ELSE 0 END) AS nullability_matches,
        CASE
            WHEN COUNT(*) = 0 THEN 'DIFF'
            WHEN COUNT(*) = SUM(CASE WHEN sc.COLUMN_NAME = vc.COLUMN_NAME THEN 1 ELSE 0 END)
             AND COUNT(*) = SUM(CASE WHEN sc.ORDINAL_POSITION = vc.ORDINAL_POSITION THEN 1 ELSE 0 END)
             AND COUNT(*) = SUM(CASE WHEN sc.DATA_TYPE = vc.DATA_TYPE THEN 1 ELSE 0 END)
             AND COUNT(*) = SUM(CASE WHEN sc.IS_NULLABLE = vc.IS_NULLABLE THEN 1 ELSE 0 END)
            THEN 'MATCH'
            ELSE 'DIFF'
        END AS schema_status
    FROM pairs p
    LEFT JOIN source_columns sc
      ON sc.TABLE_SCHEMA = p.source_schema
     AND sc.TABLE_NAME = p.source_table
    LEFT JOIN view_columns vc
      ON vc.TABLE_SCHEMA = p.view_schema
     AND vc.TABLE_NAME = p.view_name
     AND vc.ORDINAL_POSITION = sc.ORDINAL_POSITION
    GROUP BY p.source_table, p.view_name
)
SELECT
    rp.source_table,
    rp.view_name,
    rp.source_row_count,
    rp.view_row_count,
    rp.row_status,
    sp.compared_columns,
    sp.schema_status
FROM row_parity rp
JOIN schema_parity sp
  ON sp.source_table = rp.source_table
 AND sp.view_name = rp.view_name
ORDER BY rp.view_name;

WITH pairs(source_schema, source_table, view_schema, view_name) AS (
    SELECT 'ops' AS source_schema, 'orders' AS source_table, 'rpt' AS view_schema, 'vw_orders_raw' AS view_name
    UNION ALL SELECT 'ops', 'order_lines', 'rpt', 'vw_order_lines_raw'
    UNION ALL SELECT 'ops', 'customers', 'rpt', 'vw_customers_raw'
)
SELECT
    p.source_table,
    p.view_name,
    sc.ORDINAL_POSITION AS source_ordinal,
    sc.COLUMN_NAME AS source_column_name,
    vc.COLUMN_NAME AS view_column_name,
    sc.DATA_TYPE AS source_data_type,
    vc.DATA_TYPE AS view_data_type,
    sc.IS_NULLABLE AS source_is_nullable,
    vc.IS_NULLABLE AS view_is_nullable
FROM pairs p
LEFT JOIN INFORMATION_SCHEMA.COLUMNS sc
  ON sc.TABLE_SCHEMA = p.source_schema
 AND sc.TABLE_NAME = p.source_table
LEFT JOIN INFORMATION_SCHEMA.COLUMNS vc
  ON vc.TABLE_SCHEMA = p.view_schema
 AND vc.TABLE_NAME = p.view_name
 AND vc.ORDINAL_POSITION = sc.ORDINAL_POSITION
WHERE sc.COLUMN_NAME <> vc.COLUMN_NAME
   OR sc.DATA_TYPE <> vc.DATA_TYPE
   OR sc.IS_NULLABLE <> vc.IS_NULLABLE
   OR vc.COLUMN_NAME IS NULL
ORDER BY p.view_name, sc.ORDINAL_POSITION;
EOF

sqlcmd \
  -S "$DB_SERVER" \
  -d "$DB_NAME" \
  -W \
  -s "," \
  -Q "$SQL_QUERY"
