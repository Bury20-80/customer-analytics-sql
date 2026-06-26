

SELECT
	DATE_TRUNC('month',orderdate)::date  AS month_of_year,
	SUM(total_net_revenue) AS total_revenue,
	COUNT(DISTINCT customerkey) AS total_number_of_customers,
	SUM(total_net_revenue)/COUNT(DISTINCT customerkey) AS avg_revenue_per_customer 
FROM 
	cohort_analysis 
GROUP BY 
	DATE_TRUNC('month',orderdate)
ORDER BY 
	month_of_year
