/*
Raw-layer QA. Expected result for every *_issues metric is 0.
The date range and row counts identify the analyzed dataset snapshot.
*/
WITH invalid_orders AS (
    SELECT orderkey
    FROM sales
    GROUP BY orderkey
    HAVING COUNT(DISTINCT customerkey) <> 1
        OR COUNT(DISTINCT orderdate) <> 1
),
sales_checks AS (
    SELECT
        COUNT(*) AS sales_rows,
        COUNT(DISTINCT orderkey) AS distinct_orders,
        COUNT(DISTINCT customerkey) AS purchasing_customers,
        MIN(orderdate) AS min_order_date,
        MAX(orderdate) AS max_order_date,
        COUNT(*) FILTER (WHERE orderkey IS NULL) AS null_orderkey,
        COUNT(*) FILTER (WHERE customerkey IS NULL) AS null_customerkey,
        COUNT(*) FILTER (WHERE productkey IS NULL) AS null_productkey,
        COUNT(*) FILTER (WHERE orderdate IS NULL) AS null_orderdate,
        COUNT(*) FILTER (WHERE quantity IS NULL OR quantity <= 0) AS invalid_quantity,
        COUNT(*) FILTER (WHERE netprice IS NULL OR netprice < 0) AS invalid_netprice,
        COUNT(*) FILTER (WHERE unitcost IS NULL OR unitcost < 0) AS invalid_unitcost,
        COUNT(*) FILTER (WHERE exchangerate IS NULL OR exchangerate <= 0) AS invalid_exchangerate
    FROM sales
),
customer_checks AS (
    SELECT
        COUNT(*) AS customer_rows,
        COUNT(DISTINCT customerkey) AS distinct_customerkeys
    FROM customer
),
product_checks AS (
    SELECT
        COUNT(*) AS product_rows,
        COUNT(DISTINCT productkey) AS distinct_productkeys
    FROM product
)
SELECT
    s.*,
    (SELECT COUNT(*) FROM invalid_orders) AS invalid_order_ownership,
    c.customer_rows,
    c.distinct_customerkeys,
    c.customer_rows - c.distinct_customerkeys AS duplicate_customerkeys,
    p.product_rows,
    p.distinct_productkeys,
    p.product_rows - p.distinct_productkeys AS duplicate_productkeys,
    (
        SELECT COUNT(*)
        FROM sales x
        LEFT JOIN customer d ON d.customerkey = x.customerkey
        WHERE d.customerkey IS NULL
    ) AS sales_rows_without_customer,
    (
        SELECT COUNT(*)
        FROM sales x
        LEFT JOIN product d ON d.productkey = x.productkey
        WHERE d.productkey IS NULL
    ) AS sales_rows_without_product
FROM sales_checks s
CROSS JOIN customer_checks c
CROSS JOIN product_checks p;
