/*
Order-grain reconciliation. Core pass conditions:
- fact_rows = fact_distinct_orders = raw_distinct_orders
- duplicate_orderkeys = 0
- revenue_difference and quantity_difference are 0 (within numeric tolerance)
*/
WITH raw AS (
    SELECT
        COUNT(DISTINCT orderkey) AS raw_distinct_orders,
        COUNT(DISTINCT customerkey) AS raw_purchasing_customers,
        SUM(quantity * netprice / exchangerate) AS raw_revenue_usd,
        SUM(quantity) AS raw_quantity
    FROM sales
),
fact AS (
    SELECT
        COUNT(*) AS fact_rows,
        COUNT(DISTINCT orderkey) AS fact_distinct_orders,
        COUNT(DISTINCT customerkey) AS fact_purchasing_customers,
        SUM(order_revenue_usd) AS fact_revenue_usd,
        SUM(order_quantity) AS fact_quantity,
        COUNT(*) - COUNT(DISTINCT orderkey) AS duplicate_orderkeys,
        COUNT(*) FILTER (WHERE orderkey IS NULL OR customerkey IS NULL OR orderdate IS NULL)
            AS null_business_keys,
        COUNT(*) FILTER (WHERE order_revenue_usd < 0) AS negative_order_revenue,
        COUNT(*) FILTER (WHERE order_quantity <= 0) AS non_positive_order_quantity
    FROM fact_orders
)
SELECT
    f.*,
    r.raw_distinct_orders,
    r.raw_purchasing_customers,
    ROUND(f.fact_revenue_usd::numeric, 6) AS fact_revenue_check,
    ROUND(r.raw_revenue_usd::numeric, 6) AS raw_revenue_check,
    ROUND((f.fact_revenue_usd - r.raw_revenue_usd)::numeric, 6) AS revenue_difference,
    f.fact_quantity,
    r.raw_quantity,
    f.fact_quantity - r.raw_quantity AS quantity_difference
FROM fact f
CROSS JOIN raw r;
