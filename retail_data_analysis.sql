SELECT *
FROM customer;

SELECT * 
FROM prod_cat_info;

SELECT *
FROM transactions;

-- WE HAVE TO CREATE ANOTHER TABLE TO WORK ON SO AS NOT TO ALTER THE RAW DATA INCASE OF MISTAKES
-- TABLE1
CREATE TABLE customer_staging
LIKE customer;

SELECT * 
FROM customer_staging;

INSERT customer_staging
SELECT *
FROM customer;

SELECT * 
FROM customer_staging;

-- TABLE2
CREATE TABLE prod_cat_info_staging
LIKE prod_cat_info;

SELECT * 
FROM prod_cat_info_staging;

INSERT prod_cat_info_staging
SELECT *
FROM prod_cat_info;

SELECT * 
FROM prod_cat_info_staging;

-- TABLE3

CREATE TABLE transactions_staging
LIKE transactions;

SELECT * 
FROM transactions_staging;

INSERT transactions_staging
SELECT *
FROM transactions;

SELECT * 
FROM transactions_staging;
-- Data preparation and understanding
-- Q1-- NO of rows
SELECT COUNT(*) `totalnumofrows`
FROM customer_staging;

SELECT COUNT(*) `totalnumofrows`
FROM prod_cat_info_staging;

SELECT COUNT(*) `totalnumofrows`
FROM transactions_staging;

-- Q2-- No of transactions that have a return

SELECT * 
FROM transactions_staging;

SELECT COUNT(*) 
FROM transactions_staging
WHERE total_amt < 0;

-- Q3-- Convert the date variables into date formats

SELECT str_to_date(`tran_date`, '%d/%m/%Y') AS formatted_date
FROM transactions_staging;

UPDATE transactions_staging
SET tran_date = CASE
    WHEN tran_date LIKE '%-%-%' THEN STR_TO_DATE(tran_date, '%d-%m-%Y')
    WHEN tran_date LIKE '%/%/%' THEN STR_TO_DATE(tran_date, '%d/%m/%Y')
END;

ALTER TABLE transactions_staging
MODIFY COLUMN `tran_date` DATE;

SELECT tran_date,
    CASE
        WHEN tran_date LIKE '%-%-%' THEN STR_TO_DATE(tran_date, '%d-%m-%Y')
        WHEN tran_date LIKE '%/%/%' THEN STR_TO_DATE(tran_date, '%d/%m/%Y')
    END AS converted_date
FROM transactions_staging;

SELECT tran_date
FROM transactions_staging;

SELECT * 
FROM transactions_staging;

-- Q4-- Find the time range of the transaction data available in number of days, months and years in different columns

SELECT 
	MIN(tran_date) AS earliest_date,
    MAX(tran_date) AS latest_date,
    DATEDIFF(MAX(tran_date), MIN(tran_date)) AS diff_in_days,
    TIMESTAMPDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS diff_in_months,
    TIMESTAMPDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS diff_in_years
FROM transactions_staging;

-- Q5-- Which product category does the sub_category DIY belong to

SELECT * 
FROM prod_cat_info_staging
where prod_subcat like 'DIY';
    
SELECT * 
FROM prod_cat_info_staging;
    
-- DATA ANALYSIS

-- Q1-- Which channel is mostly used for transactions
    
SELECT * 
FROM transactions_staging;
    
SELECT Store_type, COUNT(*) AS transaction_count
FROM transactions_staging
group by Store_type
order by transaction_count DESC
LIMIT 1;

-- Q2--Count of male and female customers in the database
SELECT *
FROM customer_staging;

SELECT gender, COUNT(*) as count
FROM customer_staging
group by gender;

-- i had to use the where clause in the query below to avoid the blank spaces in gender

SELECT gender, COUNT(*) as count
FROM customer_staging
WHERE gender  in ('m', 'f')
group by gender;

-- Q3--From which city do we have maximum no of customers and how many

SELECT *
FROM customer_staging;

select city_code, count(*) as customers_count
from customer_staging
group by city_code
order by customers_count desc
limit 1;

-- Q4-- How many sub-categories are under the books categories

select * 
from prod_cat_info_staging;

select count(prod_subcat) as SubCategoriesCount 
from prod_cat_info
where prod_cat = 'Books'
group by prod_cat;

-- Q5-- maximum quantity of products ever ordered

SELECT * 
FROM transactions_staging;

select MAX(Qty) as max_quantity
from transactions_staging;

-- Q6--net total revenue generated in categories electronics and books 

select  sum(total_amt) as total_amount 
from transactions_staging t
	inner join prod_cat_info p on t.prod_cat_code = p.prod_cat_code 
		and t.prod_subcat_code = p.prod_sub_cat_code
where prod_cat in ('BOOKS', 'ELECTRONICS');

-- Q7--No of customers that have >10 transactions excluding returns

SELECT * 
FROM transactions_staging;

SELECT * 
FROM customer_staging;

select count(customer_id) as customer_count
from  customer_staging
where customer_Id in (
	select cust_id 
    from transactions_staging
    left join customer_staging
    on customer_Id = cust_id
    where total_amt not like '-%'
    group by cust_id
    having count(transaction_id) > 10);
    
-- Q8-- What is the combined revenue earned from 'electronics' and 'clothing' categories, from "flagship stores"

SELECT * 
FROM transactions_staging;

SELECT * 
FROM prod_cat_info_staging;

SELECT SUM(total_amt) AS amount 
FROM transactions_staging t 
	INNER JOIN prod_cat_info pci 
	ON t.prod_cat_code = pci.prod_cat_code 
	AND t.prod_subcat_code = pci.prod_sub_cat_code
WHERE prod_cat IN ('Clothing', 'Electronics') 
AND Store_type = 'Flagship Store';

-- Q9--Total revenue generated from 'male' customers in 'electronics' category. Output should display total revenue by prod_sub_cat

SELECT * 
FROM customer_staging;

select prod_subcat,sum(total_amt) as Total_Revenue
from customer_staging c inner join transactions_staging t  on c.customer_Id= t.cust_id
inner join prod_cat_info pci on t.prod_cat_code = pci.prod_cat_code 
and t.prod_subcat_code = pci.prod_sub_cat_code
where Gender ='M' and prod_cat='Electronics'
group by prod_subcat;

-- Q10-- percentage of sales and returns by product sub category; display only top 5 sub categories interms of sales

select * 
from transactions_staging;

SELECT  
    prod_subcat, 
    (SUM(total_amt) / (SELECT SUM(total_amt) FROM Transactions)) * 100 AS SalesPercentage,
    (COUNT(CASE WHEN qty < 0 THEN qty ELSE NULL END) / SUM(qty)) * 100 AS PercentageOfReturn
FROM 
    Transactions t
INNER JOIN 
    prod_cat_info pci 
    ON t.prod_cat_code = pci.prod_cat_code 
    AND prod_subcat_code = prod_sub_cat_code
GROUP BY 
    prod_subcat
ORDER BY 
    SUM(total_amt) DESC
LIMIT 5;

-- Q11--Find what is the net total revenue generated by customers aged between 25-35 in the last 30 days of transactions from max transaction date available in the data
  
SELECT CUST_ID, SUM(TOTAL_AMT) AS TotalRevenue
FROM Transactions
WHERE CUST_ID IN 
    (SELECT CUSTOMER_ID 
     FROM Customer 
     WHERE TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d/%m/%Y'), CURDATE()) BETWEEN 25 AND 35)
    AND STR_TO_DATE(tran_date, '%d/%m/%Y') BETWEEN 
        DATE_SUB((SELECT MAX(STR_TO_DATE(tran_date, '%d/%m/%Y')) FROM Transactions), INTERVAL 30 DAY)
        AND (SELECT MAX(STR_TO_DATE(tran_date, '%d/%m/%Y')) FROM Transactions)
GROUP BY CUST_ID;

-- Q12--product category that has seen the max value of returns in the last 3 months of transactions

SELECT * 
FROM transactions_staging;

SELECT 
    pci.prod_cat, 
    SUM(total_amt) AS Total_amount
FROM 
    Transactions t 
    INNER JOIN prod_cat_info pci 
        ON t.prod_cat_code = pci.prod_cat_code
        AND t.prod_subcat_code = pci.prod_sub_cat_code 
WHERE 
    total_amt < 0 
    AND STR_TO_DATE(tran_date, '%d/%m/%Y') BETWEEN DATE_ADD(
        (SELECT MAX(STR_TO_DATE(tran_date, '%d/%m/%Y')) FROM Transactions), INTERVAL -3 MONTH
    ) 
    AND (SELECT MAX(STR_TO_DATE(tran_date, '%d/%m/%Y')) FROM Transactions)
GROUP BY 
    pci.prod_cat
ORDER BY 
    Total_amount DESC
limit 1;

 -- Q13--Store type that sells the maximum products;by value of sales amount and quantity sold
 
SELECT * 
FROM transactions_staging;

SELECT 
    Store_type,
    SUM(total_amt) AS TotalSales,
    SUM(Qty) AS TotalQuantity -- 
FROM 
    Transactions
GROUP BY 
    Store_type -- groups results by store type manner
HAVING 
    SUM(total_amt) >= ALL (SELECT SUM(total_amt) FROM Transactions GROUP BY Store_type)
    AND SUM(Qty) >= ALL (SELECT SUM(Qty) FROM Transactions GROUP BY Store_type); 
		-- SUM(total_amt) >= ALL (...) ensures that storetype being considered has sales that is greater than or equal to the total sales amount of every other

-- Q14--What are the categories for which average revenue is above the overall revenue 

SELECT * 
FROM transactions_staging;

SELECT * 
FROM prod_cat_info_staging;

SELECT 
	prod_cat, AVG(total_amt) AS AvgRevenue
FROM transactions_staging t
	INNER JOIN prod_cat_info_staging pci ON t.prod_cat_code = pci.prod_cat_code 
    AND t.prod_subcat_code = pci.prod_sub_cat_code
GROUP BY prod_cat
having avg(total_amt) > (select avg(total_amt) from Transactions_staging);

-- Q15--Find average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold 

SELECT * 
FROM transactions_staging;

SELECT 
    pci.prod_cat, 
    pci.prod_subcat, 
    AVG(t.total_amt) AS Avg_revenue, 
    SUM(t.total_amt) AS Total_revenue
FROM 
    transactions_staging t
    INNER JOIN prod_cat_info pci 
        ON t.prod_cat_code = pci.prod_cat_code
        AND t.prod_subcat_code = pci.prod_sub_cat_code
WHERE 
    pci.prod_cat IN ( -- Filters the main query to include only the product categories that are in the top 5 by quantity.
        SELECT 
            top_cats.prod_cat
        FROM (
            SELECT 
                pci1.prod_cat,
                SUM(t1.qty) AS total_qty -- Selects each product category and the total quantity sold for that category.
            FROM 
                transactions_staging t1
                INNER JOIN prod_cat_info pci1 
                    ON t1.prod_cat_code = pci1.prod_cat_code
                    AND t1.prod_subcat_code = pci1.prod_sub_cat_code
            GROUP BY 
                pci1.prod_cat
            ORDER BY 
                total_qty DESC
        ) AS top_cats
    )
GROUP BY 
    pci.prod_cat, 
    pci.prod_subcat
 LIMIT 5;






    
    
    

