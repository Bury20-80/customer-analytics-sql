
WITH product_sales AS (
    SELECT
        p.categoryname,
        s.customerkey,
        (s.quantity * s.netprice / s.exchangerate)::numeric          AS line_revenue,
        (s.quantity * s.unitcost / s.exchangerate)::numeric          AS line_cost,
        ((s.netprice - s.unitcost) / NULLIF(s.netprice, 0))::numeric AS line_margin
    FROM sales s
    JOIN product p ON p.productkey = s.productkey
)
 
SELECT
    categoryname,
    COUNT(DISTINCT customerkey)                                                     AS unique_customers,
    ROUND(SUM(line_revenue), 0)                                                     AS total_revenue,
    ROUND(SUM(line_revenue) * 100.0 / SUM(SUM(line_revenue)) OVER (), 1)           AS pct_of_revenue,
    ROUND(SUM(line_revenue - line_cost), 0)                                         AS gross_profit,
    ROUND(SUM(line_revenue - line_cost) * 100.0 / NULLIF(SUM(line_revenue), 0), 1) AS avg_margin_pct,
    ROUND(SUM(line_revenue) / NULLIF(COUNT(DISTINCT customerkey), 0), 0)            AS revenue_per_customer
FROM product_sales
GROUP BY categoryname
ORDER BY total_revenue DESC;