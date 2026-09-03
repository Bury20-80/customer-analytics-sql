/*
Customer-level metrics derived only after sales lines have been collapsed
to the order grain.
Grain: exactly one row per purchasing customer.
*/
CREATE OR REPLACE VIEW int_customer_metrics AS
SELECT
    customerkey,
    MIN(orderdate) AS first_purchase_date,
    MAX(orderdate) AS last_purchase_date,
    EXTRACT(YEAR FROM MIN(orderdate))::int AS cohort_year,
    COUNT(orderkey) AS order_frequency,
    SUM(order_revenue_usd) AS lifetime_revenue_usd,
    SUM(order_gross_profit_usd) AS lifetime_gross_profit_usd,
    SUM(order_quantity) AS lifetime_quantity,
    AVG(order_revenue_usd) AS avg_order_value_usd
FROM fact_orders
GROUP BY customerkey;
