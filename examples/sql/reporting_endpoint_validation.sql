-- Public-safe example: validation checks run before report handoff

-- 1. Freshness check
select
    max(order_date) as latest_order_date,
    count(*) as total_rows
from rpt.vw_order_fulfillment_summary;

-- 2. Coverage by fulfillment status
select
    fulfillment_status,
    count(*) as row_count,
    sum(order_amount_usd) as total_amount_usd
from rpt.vw_order_fulfillment_summary
group by fulfillment_status
order by row_count desc;

-- 3. Key coverage / null check
select
    count(*) as missing_customer_name_rows
from rpt.vw_order_fulfillment_summary
where customer_name is null;

-- 4. Source vs reporting row count comparison
with source_orders as (
    select count(*) as source_count
    from stg.orders
    where is_deleted = 0
),
reporting_orders as (
    select count(*) as reporting_count
    from rpt.vw_order_fulfillment_summary
)
select
    s.source_count,
    r.reporting_count,
    s.source_count - r.reporting_count as row_count_delta
from source_orders s
cross join reporting_orders r;
