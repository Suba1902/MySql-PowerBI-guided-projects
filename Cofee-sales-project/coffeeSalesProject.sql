-- check if the data loaded completely

SELECT * FROM suba.`coffee shop sales`; -- succefully loaded

-- create a copy to avoid making changes on the raw data file

CREATE TABLE `coffee_sales` (
  `ï»¿transaction_id` int DEFAULT NULL,
  `transaction_date` text,
  `transaction_time` text,
  `transaction_qty` int DEFAULT NULL,
  `store_id` int DEFAULT NULL,
  `store_location` text,
  `product_id` int DEFAULT NULL,
  `unit_price` double DEFAULT NULL,
  `product_category` text,
  `product_type` text,
  `product_detail` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data from the rawfile to the copy

INSERT coffee_sales           
SELECT * FROM `coffee shop sales`;

-- Check the data type of columns and assign the correct data type if needed

DESCRIBE coffee_sales;

UPDATE coffee_sales   -- Updating the data type of the transaction date to date 
SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y');

SELECT * FROM coffee_sales;

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_date DATE;

UPDATE coffee_sales   -- Updating the data type of the transaction time to time time 
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_time TIME;

-- change columns names if there are typos

ALTER TABLE coffee_sales
CHANGE COLUMN TRANSACTION_ID transaction_id INT;

-- Requirement is to find "total sales for each respective month"
-- find total sales

SELECT * FROM coffee_sales;

SELECT ROUND(SUM(unit_price * transaction_qty)) AS total_sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5; -- May month 

-- selected month / current month example: May(5th month)
-- previous month - April(4th month) 

SELECT 
	MONTH(transaction_date) AS Month, -- Number of the month
	ROUND(SUM(unit_price*transaction_qty)) AS total_sales, -- total sales
    (SUM(unit_price*transaction_qty) - LAG(SUM(unit_price*transaction_qty),1) -- month sales difference
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price*transaction_qty),1) -- dividing by previous month sales
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage -- percentage calculation
FROM coffee_sales
WHERE MONTH(transaction_date) IN (4,5) -- for months April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date); 

-- -- Requirement is to find "total order for each respective month"
-- find total order

SELECT COUNT(transaction_id) AS total_orders
FROM coffee_sales
WHERE MONTH(transaction_date) = 3; -- March month 

SELECT 
	MONTH(transaction_date) AS Month, -- Number of the month
	COUNT(transaction_id) AS total_orders, -- total orders
    (COUNT(transaction_id) - LAG(COUNT(transaction_id),1) -- month orders difference
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id),1) -- dividing by previous month orders
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage -- percentage calculation
FROM coffee_sales
WHERE MONTH(transaction_date) IN (4, 5) -- for months April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date); 

-- -- Requirement is to find "total quantity sold for each respective month"
-- find total quantity sold

SELECT SUM(transaction_qty) AS total_qty_sold
FROM coffee_sales
WHERE MONTH(transaction_date) = 3; -- March month 

SELECT 
	MONTH(transaction_date) AS Month, -- Number of the month
	SUM(transaction_qty) AS total_orders, -- total quantity sold
    (SUM(transaction_qty) - LAG(SUM(transaction_qty),1) -- month quantity sold difference
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty),1) -- dividing by previous month quantity sold
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage -- percentage calculation
FROM coffee_sales
WHERE MONTH(transaction_date) IN (4, 5) -- for months April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date); 

-- we need total sales, total quantity sold and total order of a particular day

SELECT 
	CONCAT(ROUND(SUM(unit_price* transaction_qty)/1000,1), 'K') AS total_sales,
    CONCAT(ROUND(SUM(transaction_qty)/1000,1), 'K') AS total_qty_sold,
    CONCAT(ROUND(COUNT(transaction_id)/1000,1), 'K') AS total_orders
FROM coffee_sales
WHERE transaction_date = '2023-05-18';    

-- Sales on weekends and weekdays
-- Weekends -Sat and Sun (7 and 1) weekday Mon, tue, . . 2,3,..alter 

SELECT 
	CASE WHEN dayofweek(transaction_date) IN (1,7) THEN 'Weekends'
    ELSE 'Weekdays'
    END AS day_type,
    CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,1), 'K')  AS total_sales
FROM coffee_sales    
WHERE MONTH(transaction_date) = 5 -- May month
GROUP BY CASE WHEN dayofweek(transaction_date) IN (1,7) THEN 'Weekends'
    ELSE 'Weekdays'
    END ;

-- requirement to check sales data based on Location

SELECT * FROM suba.coffee_sales;

SELECT 
	store_location,
    CONCAT(ROUND(SUM(unit_price*transaction_qty)/1000,1),'K') AS total_sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5 -- May
GROUP BY store_location
ORDER BY SUM(unit_price*transaction_qty) DESC;

-- Requirement to check Daily sales analysis with Avg

SELECT AVG(unit_price*transaction_qty) AS avg_sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5; -- is not accurate

SELECT 
	CONCAT(ROUND(AVG(total_sales)/1000,1), 'k') AS avg_sales
FROM 
   (
   SELECT SUM(unit_price*transaction_qty) AS total_sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5   
GROUP BY transaction_date
) AS internal_query; 

-- Finding daily sales


SELECT 
	DAY(transaction_date) AS day_of_month,
    SUM(unit_price*transaction_qty) AS total_sales
FROM coffee_sales    
WHERE MONTH(transaction_date) = 5 
GROUP BY transaction_date
ORDER BY transaction_date;

SELECT  day_of_month,
    CASE                                                 -- Creating a condition 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM coffee_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
    
    
-- requirement to find sales with respect to category 

SELECT 
	product_category,
    SUM(unit_price*transaction_qty) AS total_sales
FROM coffee_sales        
WHERE MONTH(transaction_date) = 5
GROUP BY product_category;

-- Requirement to top 10 products by sales

SELECT 
	product_type,
    SUM(unit_price*transaction_qty) AS total_sales
FROM coffee_sales        
WHERE MONTH(transaction_date) = 5 AND product_category = 'Coffee'
GROUP BY product_type
ORDER BY SUM(unit_price*transaction_qty) DESC LIMIT 10;

-- Requirement to check Sales analysis by days and hours

SELECT 
    SUM(unit_price*transaction_qty) AS total_sales,
    SUM(transaction_qty) AS total_qty_sold,
    COUNT(*)
FROM coffee_sales        
WHERE MONTH(transaction_date) = 5 
AND DAYOFWEEK(transaction_date) = 2 -- monday
AND HOUR(transaction_time) = 14 ; -- 14 hours which is 2:00 pm

-- want to pull the hour of the transactio

SELECT 
	HOUR(transaction_time) AS hour_of_Day,
    SUM(unit_price*transaction_qty) AS total_sales
FROM coffee_sales        
WHERE MONTH(transaction_date) = 5 
GROUP BY HOUR(transaction_time)
ORDER BY HOUR(transaction_time) ;

-- want to pull the Day of the transaction

SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;

-- Create a table with all the needed column to prepare Dataset for tableau project
-- the table will have all the columns needed to meet the requirements

CREATE TABLE coffee_sales_cleaned AS
SELECT
  transaction_id,
  transaction_date,
  transaction_time,
  transaction_qty,
  store_id,
  store_location,
  product_id,
  unit_price,
  ROUND(transaction_qty * unit_price, 2) AS total_amount,
  product_category,
  product_type,
  product_detail
FROM coffee_sales
WHERE transaction_qty > 0 AND unit_price > 0;

SELECT * FROM coffee_sales_cleaned;

-- checking if there are nulls in the new table

SELECT *
FROM coffee_sales_cleaned
WHERE transaction_date IS NULL OR transaction_qty IS NULL;

-- checking if total_amount calculation failed

SELECT * 
FROM coffee_sales_cleaned
WHERE total_amount = 0;

-- checking quick insights

SELECT 
  MIN(transaction_date) AS first_date,
  MAX(transaction_date) AS last_date,
  COUNT(*) AS total_rows,
  SUM(total_amount) AS total_sales
FROM coffee_sales_cleaned;

-- export the file 



