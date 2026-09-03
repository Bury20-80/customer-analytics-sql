SELECT
    DATE_TRUNC('month', orderdate)::date AS month,
    ROUND(SUM(order_revenue_usd)::numeric, 2) AS total_revenue_usd,
    COUNT(orderkey) AS total_orders,
    COUNT(DISTINCT customerkey) AS unique_customers,
    ROUND((SUM(order_revenue_usd) / NULLIF(COUNT(DISTINCT customerkey), 0))::numeric, 2)
        AS avg_revenue_per_customer_usd,
    ROUND(AVG(order_revenue_usd)::numeric, 2) AS avg_order_value_usd
FROM fact_orders
GROUP BY DATE_TRUNC('month', orderdate)
ORDER BY month;
