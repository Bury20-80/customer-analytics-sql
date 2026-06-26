/* RFM Customer Segmentation
 
  Scores each customer on three dimensions using NTILE(5) quintiles (1=worst, 5=best):
   - Recency   : days since last purchase — fewer days = better → score inverted via (6 - NTILE)
   - Frequency : number of distinct purchase days
   - Monetary  : total lifetime revenue (USD-normalised via exchange rate in cohort_analysis)
 
  Scoring logic:
   F and M: ORDER BY ASC → NTILE=5 goes to the highest value (best) 
   R: ORDER BY ASC on days_since → NTILE=1 = fewest days (most recent)
  then (6 - NTILE) inverts the scale so R=5 = most recent (best) 
 
  Reference date: MAX(orderdate) from cohort_analysis — kept consistent
  with the view's data source to avoid discrepancies if sales contains
  records outside the cohort scope.
 
 Customers are then mapped to 9 business segments based on combined R/F/M scores.
 Dataset: Contoso 100k. 2015-01-01 to 2024-04-20
 */

WITH

-- ============================================================
-- Step 1: Aggregate raw RFM metrics per customer
-- ============================================================
reference_date AS (
    -- Isolated to a single CTE so the value is computed once, stays consistent across all calculations, 
    -- and is easy to override (e.g. swap in a fixed audit date for reproducibility).
    SELECT MAX(orderdate) AS max_order_date
    FROM cohort_analysis
),

rfm_base AS (
    SELECT
        customerkey,
        MAX(orderdate)                                                  AS last_purchase_date,
        (SELECT max_order_date FROM reference_date)
            - MAX(orderdate)                                            AS days_since_last_purchase,
        COUNT(DISTINCT orderdate)                                       AS frequency,
        SUM(total_net_revenue)                                          AS monetary
    FROM cohort_analysis
    GROUP BY customerkey
),

-- ============================================================
-- Step 2: Convert raw metrics to 1–5 scores using quintiles
-- ============================================================
rfm_scores AS (
    SELECT
        customerkey,
        last_purchase_date,
        days_since_last_purchase,
        frequency,
        ROUND(monetary::numeric, 2)                                     AS monetary,

        /*
         RECENCY SCORE
         Fewer days since last purchase = more recent = better customer.
         ORDER BY ASC  → NTILE=1 gets the smallest days_since (most recent).
         (6 - NTILE)   → inverts the scale: most recent gets R=5, oldest gets R=1.
         */
        6 - NTILE(5) OVER (ORDER BY days_since_last_purchase ASC)      AS r_score,

        /*
         FREQUENCY SCORE
        More distinct purchase days = higher loyalty.
        ORDER BY ASC → NTILE=5 goes to the most frequent buyers.
         */
        NTILE(5) OVER (ORDER BY frequency ASC)                         AS f_score,

        /*
        MONETARY SCORE
        Higher lifetime revenue = more valuable customer.
        ORDER BY ASC → NTILE=5 goes to the highest spenders.
         */
        NTILE(5) OVER (ORDER BY monetary ASC)                          AS m_score

    FROM rfm_base
),

-- ============================================================
-- Step 3: Map score combinations to business segments
-- ============================================================
rfm_segments AS (
    SELECT
        customerkey,
        last_purchase_date,
        days_since_last_purchase,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        ROUND((r_score + f_score + m_score) / 3.0, 2)                  AS rfm_avg,
        CASE
            -- Recently active, buy often, high spend
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'

            -- Less recent than Champions but still engaged and high-value
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 4
                THEN 'Loyal Customers'

            -- Bought recently but infrequently — new or newly re-engaged
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'

            -- Regular engagement but mid-range spend — upsell opportunity
            WHEN r_score >= 3 AND f_score >= 3 AND m_score <= 3
                THEN 'Potential Loyalists'

            -- Used to buy often and spend big, now going quiet — urgent win-back
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'At Risk'

            -- Declining engagement, mid-value — needs a nudge
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'Needs Attention'

            -- Spent a lot but bought rarely and not recently — last-chance win-back
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4
                THEN 'Can''t Lose Them'

            -- Low on all dimensions — likely permanently inactive
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost'

            -- Remaining cases: moderate scores across the board, low engagement trend
            ELSE 'Hibernating'
        END                                                             AS segment
    FROM rfm_scores
)

-- ============================================================
-- Step 4: Aggregate to segment-level summary
-- ============================================================
SELECT
    segment,
    COUNT(customerkey)                                                          AS customer_count,
    ROUND(COUNT(customerkey) * 100.0 / SUM(COUNT(customerkey)) OVER (), 1)     AS pct_of_customers,
    ROUND(SUM(monetary)::numeric, 0)                                            AS total_revenue,
    ROUND(AVG(monetary)::numeric, 0)                                            AS avg_ltv,
    ROUND(AVG(days_since_last_purchase)::numeric, 0)                            AS avg_days_since_purchase,
    ROUND(AVG(frequency)::numeric, 1)                                           AS avg_purchase_frequency
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;