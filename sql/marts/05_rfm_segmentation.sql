/*
RFM at customer grain.
- Recency: days since last order; lower is better.
- Frequency: number of actual orders.
- Monetary: observed lifetime revenue.

Frequency is discrete and heavily tied, so it uses transparent business-style
count bands (1, 2, 3, 4, 5+ orders). Recency and Monetary use PERCENT_RANK;
identical values receive the same percentile and therefore the same score.
*/
WITH reference_date AS (
    SELECT MAX(orderdate) AS max_order_date
    FROM fact_orders
),
rfm_base AS (
    SELECT
        c.customerkey,
        c.last_purchase_date,
        (r.max_order_date - c.last_purchase_date) AS days_since_last_purchase,
        c.order_frequency AS frequency,
        c.lifetime_revenue_usd AS monetary_usd
    FROM int_customer_metrics c
    CROSS JOIN reference_date r
),
ranked AS (
    SELECT
        b.*,
        PERCENT_RANK() OVER (ORDER BY days_since_last_purchase ASC) AS recency_pct_rank,
        PERCENT_RANK() OVER (ORDER BY monetary_usd ASC) AS monetary_pct_rank
    FROM rfm_base b
),
scored AS (
    SELECT
        r.*,
        CASE
            WHEN recency_pct_rank <= 0.20 THEN 5
            WHEN recency_pct_rank <= 0.40 THEN 4
            WHEN recency_pct_rank <= 0.60 THEN 3
            WHEN recency_pct_rank <= 0.80 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5
        END AS f_score,
        CASE
            WHEN monetary_pct_rank <= 0.20 THEN 1
            WHEN monetary_pct_rank <= 0.40 THEN 2
            WHEN monetary_pct_rank <= 0.60 THEN 3
            WHEN monetary_pct_rank <= 0.80 THEN 4
            ELSE 5
        END AS m_score
    FROM ranked r
)
SELECT
    customerkey,
    last_purchase_date,
    days_since_last_purchase,
    frequency,
    ROUND(monetary_usd::numeric, 2) AS monetary_usd,
    r_score,
    f_score,
    m_score,
    ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_avg,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 4 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score <= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN 'High-Value Inactive'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Hibernating'
    END AS segment
FROM scored
ORDER BY customerkey;
