-- Public-safe example: read-only reporting guardrails before handoff

-- 1. Expected reporting objects
select
    s.name as schema_name,
    v.name as view_name
from sys.views v
join sys.schemas s
  on s.schema_id = v.schema_id
where s.name = 'rpt'
  and v.name in ('vw_inventory_exceptions', 'vw_inventory_coverage')
order by s.name, v.name;

-- 2. Row-count baseline
select
    'rpt.vw_inventory_exceptions' as object_name,
    count(*) as rows_count
from rpt.vw_inventory_exceptions
union all
select
    'rpt.vw_inventory_coverage' as object_name,
    count(*) as rows_count
from rpt.vw_inventory_coverage;

-- 3. Key coverage indicators
select
    count(*) as total_rows,
    sum(case when item_id is null then 1 else 0 end) as missing_item_id_rows,
    sum(case when account_id is null then 1 else 0 end) as missing_account_id_rows,
    sum(case when exception_status is null then 1 else 0 end) as missing_status_rows
from rpt.vw_inventory_exceptions;

-- 4. Freshness check
select
    max(snapshot_date) as latest_snapshot_date,
    datediff(day, max(snapshot_date), cast(getdate() as date)) as snapshot_age_days
from rpt.vw_inventory_exceptions;

-- 5. Business-status distribution
select
    exception_status,
    count(*) as rows_count,
    sum(open_quantity) as open_quantity
from rpt.vw_inventory_exceptions
group by exception_status
order by rows_count desc;

-- 6. Source-to-reporting row-count comparison
with source_rows as (
    select count(*) as rows_count
    from stg.inventory_exception_source
    where is_current = 1
),
reporting_rows as (
    select count(*) as rows_count
    from rpt.vw_inventory_exceptions
)
select
    s.rows_count as source_rows_count,
    r.rows_count as reporting_rows_count,
    s.rows_count - r.rows_count as row_delta
from source_rows s
cross join reporting_rows r;
