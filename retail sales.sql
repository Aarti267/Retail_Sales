
-- CREATE DATABASE retail_sales
CREATE DATABASE retail_sales;
USE retail_sales;

SELECT * FROM sales;

-- DATA CLEANING AND TRANSFORMATION

-- Rename column ï»¿transactions_id to transaction_id
EXEC sp_rename 'sales.transactions_id', 'transaction_id', 'COLUMN';

-- Rename column quantiy to quantity
EXEC sp_rename 'sales.quantiy', 'quantity', 'COLUMN';

-- Change sale_date column to DATE
ALTER TABLE sales
ALTER COLUMN sale_date DATE;

-- Change sale_time column to TIME
ALTER TABLE sales
ALTER COLUMN sale_time TIME;

DELETE FROM sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;


-- 1.Write a SQL query to retrieve all columns for sales made on '2022-11-05'.

SELECT * FROM sales
WHERE sale_date = '2022-11-05'


-- 2.Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 3 in the month of Nov-2022.

SELECT * FROM sales
WHERE category = 'Clothing' AND MONTH(sale_date) = 11 AND YEAR(sale_date) = 2022 AND quantity > 3


-- 3.Write a SQL query to calculate the total sales (total_sale) for each category.

SELECT category, SUM(total_sale) as total_sum
FROM sales
GROUP BY category



-- 4.Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.

select round(avg(age),2)
from sales
where category = 'Beauty'



-- 5.Write a SQL query to find all transactions where the total_sale is greater than 1000

select * 
from sales
where total_sale > 1000



-- 6.Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.

select category, gender, COUNT(*)
from sales
group by category, gender
order by 1 ASC


-- 7.Write a SQL query to calculate the average sale for each month and find out the best-selling month in each year.

Select year, month, avg_sale
FROM (
SELECT 
	YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    AVG(total_sale) AS avg_sale,
    RANK() OVER ( PARTITION BY YEAR(sale_date) ORDER BY AVG(total_sale) DESC) AS rnk
FROM sales
GROUP by YEAR(sale_date), Month(sale_date)
) As t1
where rnk = 1



-- 8.Write a SQL query to find the top 5 customers based on the highest total sales.

Select TOP 5 customer_id, SUM(total_sale) AS Total_Sales
From sales
group by customer_id
order by Total_Sales DESC



-- 9.Write a SQL query to find the number of unique customers who purchased items from each category.

SELECT category, COUNT(DISTINCT customer_id) as cnt_unique
from sales
group by category


-- 10.Write a SQL query to create each shift and number of orders (Morning ≤ 12, Afternoon 12–17, Evening > 17).

WITH hourly_sale
AS
(
SELECT *,
    CASE
        WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END as shift
FROM sales
)
SELECT 
    shift,
    COUNT(*) as total_orders    
FROM hourly_sale
GROUP BY shift




-- 11.Write a SQL query to calculate the running cumulative sales for each category, ordered by sale month.

SELECT
    category,
    YEAR(sale_date) AS sale_year,
    MONTH(sale_date) AS sale_month,
    SUM(total_sale) AS monthly_sale,
    SUM(SUM(total_sale)) OVER (
        PARTITION BY category
        ORDER BY YEAR(sale_date), MONTH(sale_date)
    ) AS running_cumulative_sales
FROM sales
GROUP BY
    category,
    YEAR(sale_date),
    MONTH(sale_date)
ORDER BY
    category,
    YEAR(sale_date),
    MONTH(sale_date);




-- 12.Write a SQL query to find the month-over-month sales growth percentage for each category.
WITH MonthlySales AS
(
    SELECT
        MONTH(sale_date) AS sale_month,
        SUM(total_sale) AS current_sales
    FROM sales
    GROUP BY MONTH(sale_date)
)

SELECT
    sale_month,
    current_sales,
    LAG(current_sales, 1, 0) OVER (ORDER BY sale_month) AS previous_sales,
    ROUND(
        (
            (current_sales - LAG(current_sales, 1) OVER (ORDER BY sale_month))
            * 100.0
        ) / NULLIF(LAG(current_sales, 1) OVER (ORDER BY sale_month), 0),
        2
    ) AS mom_growth_percentage
FROM MonthlySales
ORDER BY sale_month;



-- 13.Write a SQL query to segment customers into buckets based on their total number of transactions (e.g., 1–5 = Low, 6–15 = Medium, >15 = High).

SELECT 
    customer_id, 
    COUNT(*) AS transactions, 
    CASE 
        WHEN COUNT(*) < 5 THEN 'Low'
        WHEN COUNT(*) < 15 THEN 'Medium'
        ELSE 'High'
    END AS buckets
FROM sales
GROUP BY customer_id
ORDER BY customer_id;



-- 14.Write a SQL query to find the top 3 customers based on total sales in each category using window functions.

select * from sales;
select *
from (
select category,customer_id, SUM(total_sale) as total_sales, 
rank() OVER (PARTITION BY category ORDER BY SUM(total_sale) DESC) as rnk   
from sales
group by category, customer_id
) as t1
where rnk <=3



-- 15.Write a SQL query to calculate the average number of items purchased per transaction (basket size).

select round(AVG(quantity), 2) from sales



-- 16.Write a SQL query to calculate the percentage contribution of male vs. female customers to total sales in each category.

SELECT 
    category,
    gender,
    SUM(total_sale) AS gender_sales,
    ROUND( (SUM(total_sale) * 100.0 / SUM(SUM(total_sale)) OVER (PARTITION BY category)), 2 ) AS pct_contribution
FROM sales
GROUP BY category, gender
ORDER BY category, gender;




-- 17.Write a SQL query to identify customers who purchased every month in 2023.

SELECT customer_id
FROM sales
WHERE YEAR(sale_date) = 2023
GROUP BY customer_id
HAVING COUNT(DISTINCT MONTH(sale_date)) = 12;

-- 18.Write a SQL query to calculate the percentage of customers who made more than one purchase in the same month.

WITH monthly_purchases AS (
    SELECT 
        customer_id,
        YEAR(sale_date) AS yr,
        MONTH(sale_date) AS mn,
        COUNT(*) AS purchases
    FROM sales
    GROUP BY customer_id, YEAR(sale_date), MONTH(sale_date)
),
repeat_customers AS (
    SELECT DISTINCT customer_id
    FROM monthly_purchases
    WHERE purchases > 1
)
SELECT 
    ROUND( (COUNT(DISTINCT r.customer_id) * 100.0 / COUNT(DISTINCT s.customer_id)), 2 ) AS pct_repeat_customers
FROM sales s
LEFT JOIN repeat_customers r 
    ON s.customer_id = r.customer_id;



-- 19.Write a SQL query to find the maximum single transaction value for each customer.

select TOP 1 transaction_id, SUM(total_sale)
from sales
group by transaction_id
order by 2 desc

-- 20.Write a SQL query to list all customers who haven’t purchased anything in the last 6 months.

SELECT customer_id
FROM sales
GROUP BY customer_id
HAVING MAX(sale_date) < DATEADD(MONTH, -6,(SELECT MAX(sale_date) FROM sales));


SELECT * from sales
where customer_id = 77
order by sale_date desc
