CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;
CREATE TABLE sales (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10,2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100),
    Revenue DECIMAL(15,2),
    IsCancelled VARCHAR(10),
    DayOfWeek VARCHAR(20),
    Hour INT
);
SHOW TABLES;
SELECT COUNT(*) AS total_rows
FROM sales;
SELECT *
FROM sales
LIMIT 10;

-- Total Revenue
SELECT 
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False';

-- Total Quantity Sold
SELECT 
    SUM(Quantity) AS total_quantity_sold
FROM sales
WHERE IsCancelled = 'False';

-- No of Orders
SELECT 
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM sales
WHERE IsCancelled = 'False';

-- Revenue by month
SELECT
    YEAR(InvoiceDate) AS year,
    MONTH(InvoiceDate) AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY year, month;

-- Best Revenue month
SELECT
    YEAR(InvoiceDate) AS year,
    MONTH(InvoiceDate) AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY monthly_revenue DESC
LIMIT 1;

-- Revenue by country
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY Country
ORDER BY total_revenue DESC;

-- Top 10 countries by revenue
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 products by revenue
SELECT
    Description,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
  AND Description NOT IN ('DOTCOM POSTAGE', 'POSTAGE', 'Manual')
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 Products by quantity sold
SELECT
    Description,
    SUM(Quantity) AS total_quantity
FROM sales
WHERE IsCancelled = 'False'
  AND Description NOT IN ('DOTCOM POSTAGE', 'POSTAGE', 'Manual')
GROUP BY Description
ORDER BY total_quantity DESC
LIMIT 10;

-- Top 10 customer by revenue
SELECT
    CustomerID,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
  AND CustomerID IS NOT NULL
  AND CustomerID <> ''
GROUP BY CustomerID
ORDER BY total_revenue DESC
LIMIT 10;

-- Average order values
SELECT
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT InvoiceNo),
        2
    ) AS average_order_value
FROM sales
WHERE IsCancelled = 'False';

-- Cutomer with more than one order 
SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS order_count
FROM sales
WHERE IsCancelled = 'False'
  AND CustomerID IS NOT NULL
  AND CustomerID <> ''
GROUP BY CustomerID
HAVING COUNT(DISTINCT InvoiceNo) > 1
ORDER BY order_count DESC;

-- Number of Repeat Customers
SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT CustomerID
    FROM sales
    WHERE IsCancelled = 'False'
      AND CustomerID IS NOT NULL
      AND CustomerID <> ''
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT InvoiceNo) > 1
) AS repeat_customer_list;

-- Revenue by days of week
SELECT
    DayOfWeek,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY DayOfWeek
ORDER BY total_revenue DESC;

-- Revenue by hour 
SELECT
    Hour,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales
WHERE IsCancelled = 'False'
GROUP BY Hour
ORDER BY total_revenue DESC;

SELECT
    IsCancelled,
    COUNT(*) AS transaction_count
FROM sales
GROUP BY IsCancelled;

-- Cancellation percentage
SELECT
    ROUND(
        SUM(CASE WHEN IsCancelled = 'True' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS cancellation_percentage
FROM sales;

-- Cancelled revenue
SELECT
    ROUND(SUM(ABS(Revenue)), 2) AS cancelled_revenue
FROM sales
WHERE IsCancelled = 'True';

-- Top 5 products in each country
WITH product_country_sales AS (
    SELECT
        Country,
        Description,
        ROUND(SUM(Revenue), 2) AS total_revenue
    FROM sales
    WHERE IsCancelled = 'False'
      AND Description NOT IN ('DOTCOM POSTAGE', 'POSTAGE', 'Manual')
    GROUP BY Country, Description
),
ranked_products AS (
    SELECT
        Country,
        Description,
        total_revenue,
        RANK() OVER (
            PARTITION BY Country
            ORDER BY total_revenue DESC
        ) AS product_rank
    FROM product_country_sales
)
SELECT
    Country,
    Description,
    total_revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 5
ORDER BY Country, product_rank;

-- Rank customers by revenue
WITH customer_revenue AS (
    SELECT
        CustomerID,
        ROUND(SUM(Revenue), 2) AS total_revenue
    FROM sales
    WHERE IsCancelled = 'False'
      AND CustomerID IS NOT NULL
      AND CustomerID <> ''
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    total_revenue,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS customer_rank
FROM customer_revenue
ORDER BY customer_rank;

-- Best Selling product in each country
WITH country_products AS (
    SELECT
        Country,
        Description,
        SUM(Quantity) AS total_quantity
    FROM sales
    WHERE IsCancelled = 'False'
      AND Description NOT IN ('DOTCOM POSTAGE', 'POSTAGE', 'Manual')
    GROUP BY Country, Description
),
ranked_products AS (
    SELECT
        Country,
        Description,
        total_quantity,
        RANK() OVER (
            PARTITION BY Country
            ORDER BY total_quantity DESC
        ) AS product_rank
    FROM country_products
)
SELECT
    Country,
    Description,
    total_quantity
FROM ranked_products
WHERE product_rank = 1
ORDER BY Country;

-- Monthly Revenue Growth
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS monthly_revenue
    FROM sales
    WHERE IsCancelled = 'False'
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        LAG(monthly_revenue) OVER (ORDER BY month),
        2
    ) AS previous_month_revenue,
    ROUND(
        (
            monthly_revenue -
            LAG(monthly_revenue) OVER (ORDER BY month)
        )
        * 100.0 /
        NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0),
        2
    ) AS growth_percentage
FROM monthly_sales
ORDER BY month;