

WITH Monthly_Trend AS 
(
SELECT
	DATE_TRUNC('month',orderdate)::date  AS ym,
	SUM(total_net_revenue) AS tr,
	COUNT(DISTINCT customerkey) AS tc,
	SUM(total_net_revenue)/COUNT(DISTINCT customerkey) AS ac 
FROM 
	cohort_analysis 
GROUP BY 
	DATE_TRUNC('month',orderdate)
ORDER BY 
	ym
)

SELECT
	ym AS month_of_year,
	tr AS total_revenue,
	AVG(tr) OVER(ORDER BY ym ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_avg_revenue,
	AVG(tc) OVER(ORDER BY ym ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_avg_customers,
	AVG(ac) OVER(ORDER BY ym ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rolling_avg_customer_revenue
FROM 
	Monthly_Trend
ORDER BY 
	ym