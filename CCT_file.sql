CREATE DATABASE credit_card_transactions;
DROP DATABASE credit_card_transactions;

drop table expen_data;

CREATE TABLE expend_data (
			transaction_id int,
            city varchar(255),
            transaction_date DATE,
            CARD_TYPE VARCHAR(255),
            exp_TYPE VARCHAR(255),
            gender varchar(255),
            amount BIGINT)
            ;
            
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_card_transcations.csv"
INTO TABLE expend_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select *
from expend_data;

SELECT 
	SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS transaction_id_nulls,
    SUM(CASE WHEN card_type IS NULL THEN 1 ELSE 0 END) AS card_type_nulls,
    SUM(CASE WHEN exp_type IS NULL THEN 1 ELSE 0 END) AS exp_type_nulls,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS amount_nulls,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS transaction_date_nulls
FROM expend_data;

ALTER TABLE expend_data
ADD COLUMN day_of_week VARCHAR(20); 

-- ADDING NEW TABLE TO THE TABLE

UPDATE expend_data
SET day_of_week = DAYNAME(transaction_date); -- UPDATING THE day_of_week column in the 

SELECT transaction_id, COUNT(*)
from expend_data
GROUP BY transaction_id
having count(*) > 1; -- CHECK FOR DUPLICATE ROWS

SELECT CARD_TYPE, SUM(amount) AS TOTAL_TRANSACTIONS
FROM expend_data
GROUP BY CARD_TYPE
ORDER BY TOTAL_TRANSACTIONS DESC; -- TOTAL TRANSACTION BASED ON CARD TYPE

SELECT MONTH(transaction_date) AS month, card_type, SUM(amount) AS total_expenditure
FROM expend_data
GROUP BY month, card_type
ORDER BY month, total_expenditure DESC; -- MONTHLY TRANSACTION BY CARD TYPE

SELECT MONTH(transaction_date) AS month, GENDER, SUM(amount) AS total_expenditure
FROM expend_data
GROUP BY month, GENDER
ORDER BY month, total_expenditure DESC; -- MONTHLY TRANSACTION GENDER

SELECT exp_type, GENDER, SUM(amount) AS total_expenditure
FROM expend_data
GROUP BY exp_type, GENDER
ORDER BY total_expenditure DESC; -- TRANSACTION BY TYPE OF EXPENDITURE BY GENDERS

SELECT CITY, CARD_TYPE, SUM(amount) AS total_expenditure
FROM expend_data
GROUP BY CITY, CARD_TYPE
ORDER BY total_expenditure desc
LIMIT 25; -- TRANSACTION BY TYPE DIFFERENT CARD BASED ON CITIES AND CARD TYPES

SELECT exp_TYPE, SUM(AMOUNT) AS TOTAL_EXPENDITURE, MONTH(transaction_date) AS month
FROM expend_data
GROUP BY exp_type, month
ORDER BY month, total_expenditure DESC; -- TRANSACTION BY TYPE OF EXPENDITURE 

SELECT  exp_type, avg(amount) as average_amount
FROM expend_data
GROUP BY exp_type
order by average_amount desc; -- average expense per type

SELECT YEAR(transaction_date) AS YEAR, Monthname(transaction_date) as Month, SUM(AMOUNT) AS TOTAL
FROM expend_data
GROUP BY YEAR, Month
ORDER BY TOTAL DESC
LIMIT 1;

#1)Top 5 Cities with Highest Spends and Their Percentage Contribution

WITH city_data AS 
	(SELECT CITY, SUM(amount) AS city_expenditure
	FROM expend_data
	GROUP BY CITY
	ORDER BY city_expenditure desc)
SELECT *, 
	round(cd.city_expenditure/ (SELECT SUM(AMOUNT) 
    FROM expend_data)*100,2) as spend_share
FROM city_data cd
LIMIT 5;

#2) Highest Spend Month and Amount for Each Card Type in that month

WITH h_month_exp AS
	(SELECT  year(transaction_date) as year, month(transaction_date) as month, SUM(amount) as expenditure
	FROM expend_data
	GROUP BY year, month
	ORDER BY expenditure desc
    LIMIT 1),
card_data AS
	(SELECT card_type, year(transaction_date) as year, month(transaction_date) as month, SUM(amount) as expenditure
	FROM expend_data
	GROUP BY year, month, card_type
	ORDER BY expenditure desc)
select cd.card_type, he.year, he.month, cd.expenditure
FROM h_month_exp he
join card_data cd on he.year = cd.year and he.month = cd.month
;

#3) Highest monthly expenditure for each card
SELECT year, month, card_type, total_expenditure
FROM
	(SELECT year(transaction_date) as year, month(transaction_date) AS month, card_type, SUM(amount) AS total_expenditure, 
			rank() over(partition by card_type order by SUM(amount) desc) as Ranking
	FROM expend_data
	GROUP BY year, month, card_type
	ORDER BY total_expenditure DESC) as data_month
WHERE ranking = 1; -- MONTHLY TRANSACTION BY CARD TYPE
;

#4)Cumulative Spend of 1,000,000 for Each Card Type
# To find the transaction details where each card type reaches a cumulative spend of 1,000,000:

SELECT *
from 
	(WITH cm_amount AS (select
		  *,
		  sum(amount) over(partition by card_type order by transaction_date, transaction_id) as total_spend
		 from expend_data)
	 SELECT *,
			rank() over(partition by card_type order by transaction_date, transaction_id) AS RANKING
	from CM_AMOUNT
	WHERE total_spend > 1000000) a
WHERE RANKING = 1;

#5) 5 City with Lowest Percentage Spend for Gold Card Type

with
cte1 as
 (select
  city,
  card_type,
  sum(amount) as amount,
  sum(case when card_type = 'Gold' then amount else null end) as gold_amount
 from expend_data
 group by city, card_type)
select
 city, SUM(gold_amount) AS expenditure,
 ROUND(sum(gold_amount) *100.0 / sum(amount),2) as gold_percentage
from cte1
group by city
having sum(gold_amount) is not null
order by gold_percentage
LIMIT 5;

#6) City with Highest and Lowest Expense Type
# This query identifies the highest and lowest expense types for each city:

SELECT city, exp_type, sum(amount) as amount,
		row_number() over(partition by city order by sum(amount) desc) as exp_rank
FROM expend_data
GROUP BY city, exp_type; -- THIS QUERY WILL CITY ALL ECPENDITURE AND THEIR RANK


WITH expend_type as (SELECT city, exp_type, sum(amount) as amount,
		row_number() over(partition by city order by sum(amount) desc) as exp_rank,
        row_number() over(partition by city order by sum(amount) asc) as exp_rank2
FROM expend_data
GROUP BY city, exp_type)
SELECT city, 
	MAX(CASE WHEN e.exp_rank = '1' THEN e.exp_type END) AS max_exp_type,
    MAX(CASE WHEN e.exp_rank = '1' THEN e.amount END) AS max_exp_amount,
    MAX(CASE WHEN e.exp_rank2 = '1' THEN e.exp_type END) AS min_exp_type,
    MAX(CASE WHEN e.exp_rank2 = '1' THEN e.amount END) AS min_exp_amount
FROM expend_type e
GROUP BY city;

#6) Percentage Contribution of Spends by Males and Females for Each Expense Type
# To find the percentage contribution of spends by females for each expense type:

select
 exp_type,
 round(sum(case when gender = 'M' then amount else 0 end) * 100/ sum(amount),2) as male_spend_percentage,
 round(sum(case when gender = 'F' then amount else 0 end) * 100/ sum(amount),2) as female_spend_percentage
from expend_data
group by exp_type
order by exp_type;

# 8) Card and Expense Type Combination with Highest Month-over-Month Growth in Jan-2014
# To find which card and expense type combination saw the highest month-over-month growth in January 2014:

WITH cte1 AS
	(SELECT year(transaction_date) as year, month(transaction_date) as month,
			card_type, exp_type, sum(amount) as expenditure
	FROM expend_data
	GROUP BY card_type, exp_type, year, month
	ORDER BY year, month), # GIVES THE TABLE FOR CURRENT MONTHLY EXPENDITURE 
	cte2 AS
    (SELECT *, LAG(expenditure) over(partition by card_type, exp_type order by year, month) AS prev_month_expenditure
	FROM cte1) # GIVES THE TABLE WITH PREVIOUS MONTHLY EXPENDITURE, USE OF PARTITION BY IS IMPORTANT OR ELSE THE DATA WILL GET MIXED UP
SELECT *, ROUND(100*(expenditure - prev_month_expenditure)/prev_month_expenditure,2) as monthly_growth
FROM cte2
WHERE year = 2014 and month = 1
ORDER BY monthly_growth DESC
LIMIT 1;


# 9) City with Highest Total Spend to Transaction Ratio on Weekends
# To find which city has the highest total spend to transaction count ratio on weekends
# find total amount spent to number of transaction ratio

SELECT *
FROM expend_data;

Select city, sum(amount) as expenditure, COUNT(transaction_id) as no_of_tranactions, 
		SUM(AMOUNT)/COUNT(transaction_id) as ratio
from expend_data
WHERE day_of_week IN ('SATURDAY', 'SUNDAY')
GROUP BY city
ORDER BY ratio desc
LIMIT 1;

#10) Top 5 City with Fastest to Reach 500 Transactions

WITH cte1 AS (SELECT city, transaction_date,
		count(transaction_id) over(partition by city order by transaction_date) AS num_of_transactions,
        min(transaction_date) over(partition by city order by transaction_date) AS 1st_transaction_date
FROM expend_data),
cte2 as 
	(SELECT *, row_number() over(partition by city order by transaction_date) as ranking
	FROM cte1
	WHERE num_of_transactions >= 500
	ORDER BY transaction_date)
SELECT city, transaction_date as date_for_500_transaction, num_of_transactions, 
		datediff( transaction_date, 1st_transaction_date)
 AS num_of_days
 FROM cte2
WHERE ranking = 1
limit 5;


# Total number of transactions in first 3 months for each city

WITH first_3_months as
	(SELECT DISTINCT year(transaction_date) AS YEAR, MONTH(transaction_date) AS MONTH
	FROM expend_data
    ORDER BY YEAR, MONTH
    LIMIT 3) 
SELECT * 
FROM expend_data e
WHERE EXISTS (
  SELECT 1
  FROM first_3_months f
  WHERE YEAR(e.transaction_date) = f.year
    AND MONTH(e.transaction_date) = f.month
);

#NUMBER OF TRANSACTION TILL 5,000,000 FOR EACH CARD TYPE

WITH N_transactions as 
	(SELECT transaction_id, card_type, 
			SUM(amount) over w AS cumulative_spent,
			row_number() over w AS Nth_transactions
	FROM expend_data
	window w as (partition by card_type order by transaction_id))
SELECT card_type, cumulative_spent, Nth_transactions
FROM
	(SELECT card_TYPE, CUMULATIVE_SPENT, Nth_transactions, row_number() over d AS Num_transaction
	FROM N_transactions
		WHERE cumulative_spent >5000000
	window d as (partition by card_type order by transaction_id)) a
where NUM_transaction = '1' ;

#PERCENTAGE SHARE EACH CARD TYPE
WITH total_expenditure as 
		(SELECT sum(amount) as total
		FROM expend_data),
	card_type_exp as 
		(SELECT card_type, sum(amount) as expenditure
		FROM expend_data
		GROUP BY card_type)
SELECT ce.card_type, ce.expenditure, (ce.expenditure*100/te.total) as percentage_share
FROM card_type_exp ce
CROSS JOIN total_expenditure te;


#PERCENTAGE SHARE EACH CARD TYPE
WITH total_expenditure as 
		(SELECT sum(amount) as total
		FROM expend_data),
	exp_type_share as 
		(SELECT exp_type, sum(amount) as expenditure
		FROM expend_data
		GROUP BY exp_type)
SELECT ee.exp_type, ee.expenditure, (ee.expenditure*100/te.total) as percentage_share
FROM exp_type_share ee
CROSS JOIN total_expenditure te;

SELECT year(transaction_date) as year, monthname(transaction_date) as monthname, CARD_TYPE, Sum(amount) as Amount, month(transaction_date) as month
FROM expend_data
group by year, monthname, card_type, month
order by year, month;
