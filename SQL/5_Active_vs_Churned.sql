-- NOTE: 90.5% churn rate is expected given the 2015–2024 data range.
-- With a 6-month inactivity threshold, most historical customers
-- naturally fall into the Churned bucket. This is not a data issue.

-- NOTE: ~5.2% of customers (those with first_purchase_date within
-- the last 6 months) are intentionally excluded from this analysis
-- as they have not had sufficient time to be evaluated for churn.


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
            WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months' THEN 'Churned'
            ELSE 'Active'
        END AS customer_status
    FROM customer_last_purchase
    WHERE rn = 1
        AND first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months'
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