USE sports_ecommerce;

-- ============================================================
-- SPORTS E-COMMERCE SQL PROJECT
-- ADVANCED SQL QUERIES
-- Queries 31 - 40
-- ============================================================


-- ============================================================
-- QUERY 31
-- Which products generated revenue above the average
-- product revenue?
-- ============================================================

SELECT
    p.ProductKey,
    p.ProductName,
    ROUND(SUM(s.SalesAmount), 2) AS total_revenue
FROM products p
JOIN sales s
    ON p.ProductKey = s.ProductKey
GROUP BY p.ProductKey, p.ProductName
HAVING SUM(s.SalesAmount) >
(
    SELECT AVG(product_revenue)
    FROM
    (
        SELECT
            ProductKey,
            SUM(SalesAmount) AS product_revenue
        FROM sales
        GROUP BY ProductKey
    ) AS revenue_summary
)
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 32
-- Which customers spent more than the average customer?
-- ============================================================

SELECT
    c.CustomerKey,
    c.FullName,
    ROUND(SUM(s.SalesAmount), 2) AS total_spent
FROM customers c
JOIN sales s
    ON c.CustomerKey = s.CustomerKey
GROUP BY c.CustomerKey, c.FullName
HAVING SUM(s.SalesAmount) >
(
    SELECT AVG(customer_spending)
    FROM
    (
        SELECT
            CustomerKey,
            SUM(SalesAmount) AS customer_spending
        FROM sales
        GROUP BY CustomerKey
    ) AS customer_summary
)
ORDER BY total_spent DESC;


-- ============================================================
-- QUERY 33
-- Rank all products based on total revenue.
-- ============================================================

SELECT
    p.ProductKey,
    p.ProductName,
    ROUND(SUM(s.SalesAmount), 2) AS total_revenue,
    RANK() OVER (
        ORDER BY SUM(s.SalesAmount) DESC
    ) AS revenue_rank
FROM products p
JOIN sales s
    ON p.ProductKey = s.ProductKey
GROUP BY p.ProductKey, p.ProductName
ORDER BY revenue_rank;


-- ============================================================
-- QUERY 34
-- Rank products within each product category based on revenue.
-- ============================================================

SELECT
    p.Category,
    p.ProductKey,
    p.ProductName,
    ROUND(SUM(s.SalesAmount), 2) AS total_revenue,
    RANK() OVER (
        PARTITION BY p.Category
        ORDER BY SUM(s.SalesAmount) DESC
    ) AS category_rank
FROM products p
JOIN sales s
    ON p.ProductKey = s.ProductKey
GROUP BY
    p.Category,
    p.ProductKey,
    p.ProductName
ORDER BY
    p.Category,
    category_rank;


-- ============================================================
-- QUERY 35
-- Find the top 3 products in each category.
-- ============================================================

WITH product_ranking AS
(
    SELECT
        p.Category,
        p.ProductKey,
        p.ProductName,
        ROUND(SUM(s.SalesAmount), 2) AS total_revenue,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY SUM(s.SalesAmount) DESC
        ) AS category_rank
    FROM products p
    JOIN sales s
        ON p.ProductKey = s.ProductKey
    GROUP BY
        p.Category,
        p.ProductKey,
        p.ProductName
)

SELECT
    Category,
    ProductKey,
    ProductName,
    total_revenue,
    category_rank
FROM product_ranking
WHERE category_rank <= 3
ORDER BY Category, category_rank;


-- ============================================================
-- QUERY 36
-- Calculate monthly revenue and rank the months
-- from highest to lowest revenue.
-- ============================================================

WITH monthly_revenue AS
(
    SELECT
        DATE_FORMAT(
            STR_TO_DATE(OrderDate, '%Y-%m-%d'),
            '%Y-%m'
        ) AS sales_month,
        SUM(SalesAmount) AS total_revenue
    FROM sales
    GROUP BY
        DATE_FORMAT(
            STR_TO_DATE(OrderDate, '%Y-%m-%d'),
            '%Y-%m'
        )
)

SELECT
    sales_month,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM monthly_revenue
ORDER BY revenue_rank;


-- ============================================================
-- QUERY 37
-- Calculate each product's percentage contribution
-- to total revenue.
-- ============================================================

WITH product_revenue AS
(
    SELECT
        p.ProductKey,
        p.ProductName,
        SUM(s.SalesAmount) AS total_revenue
    FROM products p
    JOIN sales s
        ON p.ProductKey = s.ProductKey
    GROUP BY
        p.ProductKey,
        p.ProductName
)

SELECT
    ProductKey,
    ProductName,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        total_revenue * 100.0 /
        SUM(total_revenue) OVER (),
        2
    ) AS revenue_percentage
FROM product_revenue
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 38
-- Find the highest-revenue product for each category.
-- ============================================================

WITH category_products AS
(
    SELECT
        p.Category,
        p.ProductKey,
        p.ProductName,
        SUM(s.SalesAmount) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.Category
            ORDER BY SUM(s.SalesAmount) DESC
        ) AS product_rank
    FROM products p
    JOIN sales s
        ON p.ProductKey = s.ProductKey
    GROUP BY
        p.Category,
        p.ProductKey,
        p.ProductName
)

SELECT
    Category,
    ProductKey,
    ProductName,
    ROUND(total_revenue, 2) AS total_revenue
FROM category_products
WHERE product_rank = 1
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 39
-- Create a reusable view showing monthly sales performance.
-- ============================================================

CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT
    DATE_FORMAT(
        STR_TO_DATE(OrderDate, '%Y-%m-%d'),
        '%Y-%m'
    ) AS sales_month,
    COUNT(DISTINCT SalesOrderNumber) AS total_orders,
    SUM(OrderQuantity) AS total_units_sold,
    ROUND(SUM(SalesAmount), 2) AS total_revenue,
    ROUND(
        SUM(SalesAmount - TotalProductCost),
        2
    ) AS total_profit
FROM sales
GROUP BY
    DATE_FORMAT(
        STR_TO_DATE(OrderDate, '%Y-%m-%d'),
        '%Y-%m'
    );


-- Test the view created above

SELECT *
FROM monthly_sales_summary
ORDER BY sales_month;


-- ============================================================
-- QUERY 40
-- Create a stored procedure to retrieve the purchase
-- history of a specific customer.
-- ============================================================

DROP PROCEDURE IF EXISTS GetCustomerSales;

DELIMITER $$
CALL GetCustomerSales(11037);

CREATE PROCEDURE GetCustomerSales(IN customer_id INT)
BEGIN

    SELECT
        c.CustomerKey,
        c.FullName,
        s.SalesID,
        s.OrderDate,
        p.ProductName,
        p.Category,
        s.OrderQuantity,
        s.UnitPrice,
        s.SalesAmount
    FROM customers c
    JOIN sales s
        ON c.CustomerKey = s.CustomerKey
    JOIN products p
        ON s.ProductKey = p.ProductKey
    WHERE c.CustomerKey = customer_id
    ORDER BY s.OrderDate;

END $$

DELIMITER ;


-- Test the stored procedure
-- Replace 11037 with a CustomerKey that exists in your database.

CALL GetCustomerSales(11037);


-- ============================================================
-- END OF ADVANCED QUERIES
-- ============================================================