COHORT_ANALYSIS_RAW = """
SELECT *
FROM cohort_analysis
"""

MONTHLY_REVENUE_TRENDS = """
SELECT
    DATE_TRUNC('month', orderdate)::date AS month_of_year,
    SUM(total_net_revenue) AS total_revenue,
    COUNT(DISTINCT customerkey) AS total_number_of_customers,
    SUM(total_net_revenue) / COUNT(DISTINCT customerkey) AS avg_revenue_per_customer
FROM cohort_analysis
GROUP BY DATE_TRUNC('month', orderdate)
ORDER BY month_of_year
"""

CUSTOMER_LTV = """
SELECT
    customerkey,
    SUM(total_net_revenue) AS total_ltv
FROM cohort_analysis
GROUP BY customerkey
"""

CUSTOMER_PURCHASE_DATES = """
SELECT DISTINCT
    customerkey,
    orderdate
FROM cohort_analysis
ORDER BY customerkey, orderdate
"""

RFM_BASE = """
SELECT
    customerkey,
    MAX(orderdate) AS last_purchase_date,
    (SELECT MAX(orderdate) FROM cohort_analysis) - MAX(orderdate) AS days_since_last_purchase,
    COUNT(DISTINCT orderdate) AS frequency,
    SUM(total_net_revenue) AS monetary
FROM cohort_analysis
GROUP BY customerkey
"""

PRODUCT_ANALYSIS = """
WITH product_sales AS (
    SELECT
        p.categoryname,
        s.customerkey,
        (s.quantity * s.netprice / s.exchangerate)::numeric AS line_revenue,
        (s.quantity * s.unitcost / s.exchangerate)::numeric AS line_cost
    FROM sales s
    JOIN product p ON p.productkey = s.productkey
)
SELECT
    categoryname,
    COUNT(DISTINCT customerkey) AS unique_customers,
    ROUND(SUM(line_revenue), 0) AS total_revenue,
    ROUND(SUM(line_revenue - line_cost), 0) AS gross_profit,
    ROUND(SUM(line_revenue - line_cost) * 100.0 / NULLIF(SUM(line_revenue), 0), 1) AS avg_margin_pct
FROM product_sales
GROUP BY categoryname
ORDER BY total_revenue DESC
"""

NEW_VS_RETURNING = """
WITH customer_orders AS (
    SELECT
        customerkey,
        orderdate,
        total_net_revenue,
        first_purchase_date,
        DATE_TRUNC('month', orderdate)::date AS order_month,
        DATE_TRUNC('month', first_purchase_date)::date AS first_month
    FROM cohort_analysis
),
monthly_classified AS (
    SELECT
        order_month,
        customerkey,
        total_net_revenue,
        CASE WHEN order_month = first_month THEN 'New' ELSE 'Returning' END AS customer_type
    FROM customer_orders
)
SELECT
    order_month AS month,
    COUNT(DISTINCT CASE WHEN customer_type = 'New' THEN customerkey END) AS new_customers,
    COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customerkey END) AS returning_customers,
    SUM(CASE WHEN customer_type = 'New' THEN total_net_revenue ELSE 0 END) AS new_revenue,
    SUM(CASE WHEN customer_type = 'Returning' THEN total_net_revenue ELSE 0 END) AS returning_revenue
FROM monthly_classified
GROUP BY order_month
ORDER BY order_month
"""

ACTIVE_VS_CHURNED = """
WITH customer_last_purchase AS (
    SELECT
        customerkey,
        orderdate,
        ROW_NUMBER() OVER (PARTITION BY customerkey ORDER BY orderdate DESC) AS rn,
        first_purchase_date,
        cohort_year
    FROM cohort_analysis
),
churned_customers AS (
    SELECT
        customerkey,
        orderdate AS last_purchase_date,
        cohort_year,
        CASE
            WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '558 days' THEN 'Churned'
            ELSE 'Active'
        END AS customer_status
    FROM customer_last_purchase
    WHERE rn = 1
        AND first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '558 days'
)
SELECT
    cohort_year,
    customer_status,
    COUNT(customerkey) AS num_customers,
    SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year) AS total_customers,
    ROUND(COUNT(customerkey) / SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year), 2) AS cohort_percentage
FROM churned_customers
GROUP BY cohort_year, customer_status
ORDER BY cohort_year, customer_status
"""

RFM_SEGMENTS = """
WITH reference_date AS (
    SELECT MAX(orderdate) AS max_order_date FROM cohort_analysis
),
rfm_base AS (
    SELECT
        customerkey,
        (SELECT max_order_date FROM reference_date) - MAX(orderdate) AS days_since_last_purchase,
        COUNT(DISTINCT orderdate) AS frequency,
        SUM(total_net_revenue) AS monetary
    FROM cohort_analysis
    GROUP BY customerkey
),
rfm_scores AS (
    SELECT
        customerkey,
        days_since_last_purchase,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY days_since_last_purchase ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        customerkey,
        days_since_last_purchase,
        frequency,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 4 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score <= 3 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN 'Can''t Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            ELSE 'Hibernating'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(customerkey) AS customer_count,
    ROUND(SUM(monetary)::numeric, 0) AS total_revenue,
    ROUND(AVG(monetary)::numeric, 0) AS avg_ltv,
    ROUND(AVG(days_since_last_purchase)::numeric, 0) AS avg_days_since_purchase
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC
"""
