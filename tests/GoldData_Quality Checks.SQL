

--------------------------------------------------------------------------------------------
--check for uniqueness of customer key, 
--expectation No results

SELECT   customer_key,
         COUNT(*)
FROM     gold.dim_customers
GROUP BY customer_key
HAVING   COUNT(*) > 1;





--------------------------------------------------------------------------------------------
--check that  final table is okay and that the surrogate keys are unique and don't overlap
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
