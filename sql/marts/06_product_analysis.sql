WITH product_sales AS (
    SELECT
        TRIM(p.categoryname) AS categoryname,
        s.customerkey,
        (s.quantity * s.netprice / s.exchangerate)::numeric AS line_revenue_usd,
        (s.quantity * s.unitcost / s.exchangerate)::numeric AS line_cost_usd
    FROM sales s
    JOIN product p
        ON p.productkey = s.productkey
)
SELECT
    categoryname,
    COUNT(DISTINCT customerkey) AS unique_customers,
    ROUND(SUM(line_revenue_usd), 0) AS total_revenue_usd,
    ROUND(SUM(line_revenue_usd) * 100.0 / SUM(SUM(line_revenue_usd)) OVER (), 1)
        AS pct_of_revenue,
    ROUND(SUM(line_revenue_usd - line_cost_usd), 0) AS gross_profit_usd,
    ROUND(
        SUM(line_revenue_usd - line_cost_usd) * 100.0
        / NULLIF(SUM(line_revenue_usd), 0),
        1
    ) AS gross_margin_pct,
    ROUND(SUM(line_revenue_usd) / NULLIF(COUNT(DISTINCT customerkey), 0), 0)
        AS revenue_per_customer_usd
FROM product_sales
GROUP BY categoryname
ORDER BY total_revenue_usd DESC;
