/*
Observed intervals between consecutive orders.
Grain: one row per repeat order (the first order of each customer is excluded).
Ordering by orderdate + orderkey makes same-day orders deterministic.
*/
CREATE OR REPLACE VIEW int_repeat_purchase_intervals AS
WITH ordered_orders AS (
    SELECT
        customerkey,
        orderkey,
        orderdate,
        LAG(orderdate) OVER (
            PARTITION BY customerkey
            ORDER BY orderdate, orderkey
        ) AS previous_order_date
    FROM fact_orders
)
SELECT
    customerkey,
    orderkey,
    orderdate,
    previous_order_date,
    orderdate - previous_order_date AS gap_days
FROM ordered_orders
WHERE previous_order_date IS NOT NULL;
