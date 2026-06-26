

WITH customer_orders AS (
    SELECT
        customerkey,
        orderdate,
        total_net_revenue,
        first_purchase_date,
        DATE_TRUNC('month', orderdate)::date             AS order_month,
        DATE_TRUNC('month', first_purchase_date)::date   AS first_month
    FROM cohort_analysis
),

monthly_classified AS (
    SELECT
        order_month,
        customerkey,
        total_net_revenue,
        CASE
            WHEN order_month = first_month THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM customer_orders
)

SELECT
    order_month                                                              AS month,
    COUNT(DISTINCT CASE WHEN customer_type = 'New'       THEN customerkey END)  AS new_customers,
    COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customerkey END)  AS returning_customers,
    COUNT(DISTINCT customerkey)                                              AS total_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customerkey END) * 100.0
        / NULLIF(COUNT(DISTINCT customerkey), 0), 1
    )                                                                        AS returning_pct,
    ROUND(SUM(CASE WHEN customer_type = 'New'       THEN total_net_revenue ELSE 0 END)::numeric, 0) AS new_revenue,
    ROUND(SUM(CASE WHEN customer_type = 'Returning' THEN total_net_revenue ELSE 0 END)::numeric, 0) AS returning_revenue,
    ROUND(SUM(total_net_revenue)::numeric, 0)                                AS total_revenue
FROM monthly_classified
GROUP BY order_month
ORDER BY order_month;