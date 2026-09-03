SELECT
    customerkey,
    orderkey,
    orderdate,
    previous_order_date,
    gap_days
FROM int_repeat_purchase_intervals
ORDER BY customerkey, orderdate, orderkey;
