/*
Inactivity is a heuristic status, not a churn probability.
The threshold is the median observed interval between consecutive orders.
Only customers whose first order is old enough to have a full threshold-sized
observation window are included in the cohort comparison.
*/
WITH params AS (
    SELECT
        (SELECT MAX(orderdate) FROM fact_orders) AS reference_date,
        ROUND(
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_days)
        )::int AS inactivity_days
    FROM int_repeat_purchase_intervals
),
eligible_customers AS (
    SELECT
        c.customerkey,
        c.cohort_year,
        c.first_purchase_date,
        c.last_purchase_date,
        p.reference_date,
        p.inactivity_days,
        CASE
            WHEN c.last_purchase_date < p.reference_date - p.inactivity_days * INTERVAL '1 day'
                THEN 'Inactive'
            ELSE 'Recent'
        END AS customer_status
    FROM int_customer_metrics c
    CROSS JOIN params p
    WHERE c.first_purchase_date < p.reference_date - p.inactivity_days * INTERVAL '1 day'
)
SELECT
    cohort_year,
    customer_status,
    MAX(inactivity_days) AS inactivity_threshold_days,
    COUNT(*) AS customers,
    SUM(COUNT(*)) OVER (PARTITION BY cohort_year) AS eligible_customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY cohort_year),
        1
    ) AS cohort_pct
FROM eligible_customers
GROUP BY cohort_year, customer_status
ORDER BY cohort_year, customer_status;
