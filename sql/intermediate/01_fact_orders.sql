/*
Order-level fact table.
Grain: exactly one row per orderkey.

Run sql/validation/01_raw_data_audit.sql before creating this view.
The audit is expected to confirm that each orderkey belongs to one customer
and one order date, and that exchangerate is positive.
*/
CREATE OR REPLACE VIEW fact_orders AS
WITH order_level AS (
    SELECT
        s.orderkey,
        s.customerkey,
        s.orderdate,
        SUM(s.quantity * s.netprice / s.exchangerate) AS order_revenue_usd,
        SUM(s.quantity * s.unitcost / s.exchangerate) AS order_cost_usd,
        SUM(s.quantity * (s.netprice - s.unitcost) / s.exchangerate) AS order_gross_profit_usd,
        SUM(s.quantity) AS order_quantity,
        COUNT(*) AS sales_line_count
    FROM sales s
    GROUP BY
        s.orderkey,
        s.customerkey,
        s.orderdate
)
SELECT
    o.*,
    MIN(o.orderdate) OVER (PARTITION BY o.customerkey) AS first_purchase_date,
    EXTRACT(YEAR FROM MIN(o.orderdate) OVER (PARTITION BY o.customerkey))::int AS cohort_year
FROM order_level o;
