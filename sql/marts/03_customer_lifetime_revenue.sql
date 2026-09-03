/*
Observed customer lifetime revenue, not a predictive CLV model.
Q1/Q3 thresholds form three descriptive value tiers.
*/
WITH thresholds AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY lifetime_revenue_usd) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY lifetime_revenue_usd) AS q3
    FROM int_customer_metrics
)
SELECT
    c.customerkey,
    c.order_frequency,
    ROUND(c.lifetime_revenue_usd::numeric, 2) AS lifetime_revenue_usd,
    ROUND(c.avg_order_value_usd::numeric, 2) AS avg_order_value_usd,
    CASE
        WHEN c.lifetime_revenue_usd < t.q1 THEN 'Low-Value'
        WHEN c.lifetime_revenue_usd <= t.q3 THEN 'Mid-Value'
        ELSE 'High-Value'
    END AS customer_segment
FROM int_customer_metrics c
CROSS JOIN thresholds t
ORDER BY c.lifetime_revenue_usd DESC, c.customerkey;
