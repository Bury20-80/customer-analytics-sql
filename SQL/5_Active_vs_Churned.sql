-- CHURN THRESHOLD — UPDATED FROM 180 DAYS TO 558 DAYS (MEDIAN)
-- Original 180-day (6-month) threshold was validated against the actual
-- distribution of days between purchases for the same customer
-- (see python/notebooks/3_statistical_analysis.ipynb).
--
-- The median (558 days) was chosen as the threshold: it is the point
-- where a customer is statistically more likely to be inactive than
-- active
--
-- NOTE: this value is a snapshot computed in Python at analysis time,
-- If the underlying sales data changes materially,
-- re-run the notebook and update this constant manually
 
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
GROUP BY
    cohort_year,
    customer_status
ORDER BY
    cohort_year,
    customer_status;