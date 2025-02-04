/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || COALESCE(product_size,'')|| ' (' || COALESCE(product_qty_type,'unit') || ')'
FROM product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT *
--,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY market_date ASC) as row_num
--If want unique  market dates, use the one below.
,DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY market_date ASC) as [dense_rank]
FROM customer_purchases

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT *
FROM(
	SELECT *
	,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY market_date DESC) as row_num
	FROM customer_purchases
	) x
WHERE x.row_num =1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT *
,COUNT(*) OVER (PARTITION BY product_id,customer_id) as num_times

FROM customer_purchases
--this is assuming 


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name
,TRIM(SUBSTR(product_name, NULLIF(INSTR(product_name, '-')+1,1))) as description
--since when there's no hyphen the nullif will return null, 
--substr will return null having its starting position null.

FROM product

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT *

FROM product

WHERE product_size REGEXP('[0-9]+')

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


/*Step 1. Make a temporary table called sales_per_day based on customer_purchases table.
This table should have two columns: 
    1. market_date: existing column
    2. sales: new column derived from the SUM of quantity * cost_to_customer_per_qty (group by market_date)
*/
DROP TABLE IF EXISTS temp.sales_per_day;
CREATE TABLE temp.sales_per_day AS
SELECT
market_date
, SUM(quantity * cost_to_customer_per_qty) as sales
FROM customer_purchases 
GROUP BY market_date

/*Step 2. Make another temporary table called sales_ranked_by_date based on sales_per_day (the temp table created in step 1). 
This table should have four columns: 
    1. market_date, 
	2. sales,
	3. sales_rank_ascending:  new column that uses RANK() windowed function to rank sales in ascending order
	4. sales_rank_descending:  new column that uses RANK() windowed function to rank sales in descending order
*/
DROP TABLE IF EXISTS temp.sales_ranked_by_date;
CREATE TABLE temp.sales_ranked_by_date AS
SELECT
spd.market_date
,spd.sales
,RANK() OVER(ORDER BY sales ASC) as sales_rank_ascending
,RANK() OVER(ORDER BY sales DESC) as sales_rank_descending

FROM sales_per_day as spd

/*Step 3. Make a query that selects market_date, sales, sales_rank_desc from sales_ranked_by_date table.
Filter the table to get the row with the BEST ranking sales.


Step 4. Make another query that selects the same sets of columns from sales_ranked_by_date table.
Filter the table to get the row with the WORST ranking sales.

Step 5. Union the two queries from Step 3 and Step 4. Your result should have only two rows which are the best and the worst day of sales
*/

SELECT 
srbd.market_date
,srbd.sales
,srbd.sales_rank_descending
FROM sales_ranked_by_date as srbd
WHERE srbd.sales_rank_descending = 1

UNION

SELECT 
srbd.market_date
,srbd.sales
,srbd.sales_rank_descending
FROM sales_ranked_by_date as srbd
WHERE srbd.sales_rank_ascending = 1


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT 
    x.vendor_name,
    x.product_name,
    SUM(x.tot_5_price) AS total_money	
	
	
FROM
	(
    SELECT DISTINCT
	customer_id,
	 v.vendor_name
	, p.product_name
	, vi.original_price*5 as tot_5_price
	FROM vendor as v, product as p
	INNER JOIN vendor_inventory as vi
		ON v.vendor_id = vi.vendor_id AND vi.product_id = p.product_id
	CROSS JOIN 
	(SELECT DISTINCT customer_id
    From customer)
    ) as x
GROUP BY x.vendor_name, x.product_name


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */


DROP TABLE IF EXISTS temp.product_units; 
CREATE TEMP TABLE IF NOT EXISTS temp.product_units as
	SELECT *, 
	CURRENT_TIMESTAMP as snapshot_timestamp 
	FROM product 
	WHERE product_qty_type = 'unit';
	


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES(26, 'Apple Pie', '10"',	3,'unit', '2025-02-03 23:11:43');


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units 
WHERE product_id=7; -- removing the old record of apple pie (product_id=7)


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


/*Step 1. Execute the given code to add current_quantity column to product_units table*/
ALTER TABLE product_units
ADD current_quantity INT;

/*Step 2. Make a temporary table called latest_product based on vendor_inventory table.
Select all the columns
Select MAX(market_date) to get the data with the latest market_date for every product(Group By product_id)
*/
DROP TABLE IF EXISTS temp.latest_product;
CREATE TEMP TABLE temp.latest_product AS
SELECT *
, MAX(vi.market_date) as max_date
FROM vendor_inventory as vi
GROUP BY vi.product_id;




UPDATE product_units
SET current_quantity = COALESCE((
  SELECT current_quantity 
  FROM (
  
   /*Step 3. Join product_units with latest_product on product_id.
   This joined table should have the following columns:
   1. product_id
   2. current_quantity: derived from 'quantity' with the use of COALESCE to handle NULL values
   */
    SELECT  
	pu.product_id
	,COALESCE(lp.quantity,0) as current_quantity
    FROM latest_product as lp
    LEFT JOIN  product_units as pu
    ON lp.product_id = pu.product_id
	
  ) p

WHERE product_units.product_id = p.product_id),0);
