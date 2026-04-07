-- Public-safe example: reporting-facing consumption view
-- Purpose: expose a stable business-ready endpoint rather than pointing reports
-- directly at raw operational tables.

create or replace view rpt.vw_order_fulfillment_summary as
with order_base as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.required_ship_date,
        o.actual_ship_date,
        o.order_status,
        o.order_amount_usd
    from stg.orders o
    where o.is_deleted = 0
),
shipment_flags as (
    select
        ob.order_id,
        case
            when ob.actual_ship_date is null then 'Open'
            when ob.actual_ship_date <= ob.required_ship_date then 'On Time'
            else 'Late'
        end as fulfillment_status,
        datediff(day, ob.order_date, coalesce(ob.actual_ship_date, current_date)) as days_since_order
    from order_base ob
)
select
    ob.order_id as reporting_order_id,
    c.customer_name,
    c.customer_segment,
    cast(ob.order_date as date) as order_date,
    cast(ob.required_ship_date as date) as required_ship_date,
    cast(ob.actual_ship_date as date) as actual_ship_date,
    sf.fulfillment_status,
    sf.days_since_order,
    ob.order_status,
    ob.order_amount_usd
from order_base ob
left join dim.customer c
    on ob.customer_id = c.customer_id
left join shipment_flags sf
    on ob.order_id = sf.order_id;
