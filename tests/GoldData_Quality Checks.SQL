/*
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
QUALITY CHECKS
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Script Purpose:
The scripts below perform quality checks to validate the integrity, consistency and accuracy of the gold layer. These checks ensure
1. Uniqueness of the surrogate keysin dimension tables
2. Referential integrity between the fact and dimension tables
3. Validation of the relationships between the data model for analytical purposes
- Run these checks after data loading the silver layer
- Investigate and resolve any issues that come up during the checks

*/

--------------------------------------------------------------------------------------------
--check for uniqueness of customer key, 
--expectation No results

SELECT   customer_key,
         COUNT(*)
FROM     gold.dim_customers
GROUP BY customer_key
HAVING   COUNT(*) > 1;





--------------------------------------------------------------------------------------------
--check the data model connectivity between fact and dimensions
--foreign key integrity (dimensions)

select * from gold.fact_sales AS f 
left join gold.dim_products AS p
on f.product_key = p.product_key
left join gold.dim_customers c
on f.customer_key = c.customer_key
where f.customer_key is null
 

 --------------------------------------------------------------------------------------------
 --get information for the data catalogue preparation

EXEC sp_help  'gold.fact_sales';
SELECT *
FROM sys.objects
WHERE name = 'gold.dim_products';
gold.dim_customersgold.fact_sales
