WITH monthly AS (
    SELECT
        DATE_TRUNC('month', orderdate)::date AS month,
        SUM(order_revenue_usd) AS monthly_revenue_usd
    FROM fact_orders
    GROUP BY DATE_TRUNC('month', orderdate)
)
SELECT
    month,
    ROUND(monthly_revenue_usd::numeric, 2) AS monthly_revenue_usd,
    ROUND(
        AVG(monthly_revenue_usd) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric,
        2
    ) AS trailing_3m_avg_revenue_usd
FROM monthly
ORDER BY month;
