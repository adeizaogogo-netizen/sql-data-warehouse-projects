/* 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                                               DDL SCRIPT: CREATE GOLD VIEWS
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

This script creates views for the Gold layer in the the data warehouse. The goldlayer represents the final dimension
and fact tables (star schema)
Each view performs transformations and combines data from the silver layer to provide a clean, enriched and business
-ready dataset.

Usage:
These views can be queried directly for analytics and reporting

*/

-----------------------------------------------------------------------------------------------------
-- Create Dimension: gold.dim_customers
-----------------------------------------------------------------------------------------------------

CREATE VIEW gold.dim_customers AS 
SELECT 
       ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
       ci.cst_id AS customer_id,                    -- Primary Key (check that there is not duplicate record for the PK)
       ci.cst_key AS customer_number,
       ci.cst_firstname AS first_name,
       ci.cst_lastname AS last_name,
       cl.cntry AS country,
       ci.cst_marital_status AS marital_status,
       cb.bdate AS birth_date,
       CASE
            WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
            ELSE COALESCE(cb.gen, 'n/a')
       END AS gender,
       ci.cst_create_date AS create_date
  FROM silver.crm_cust_info AS ci                   -- Customer information (ci)
  LEFT OUTER JOIN silver.erp_cust_az12 AS cb        -- Customer birthday (cb)
    ON ci.cst_key = cb.cid
  LEFT OUTER JOIN silver.erp_loc_a101 AS cl         -- Customer location (cl)
    ON ci.cst_key = cl.cid;

/*
Rename the columns using the naming convention outlined in documentation
1. Use snake_case: with lowercase letters and underscores
2. USe English for all names
3. Avoid using any reserved SQL words as object names

*/

-----------------------------------------------------------------------------------------------------
-- Create Dimension: gold.dim_products
-----------------------------------------------------------------------------------------------------


CREATE OR ALTER VIEW gold.dim_products AS

SELECT ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
       pn.prd_id AS product_id,
       pn.prd_key AS product_number,
       pn.prd_nm AS product_name,
       pn.cat_id AS category_id,
       pm.cat AS category,
       pm.subcat AS subcategory,
       pm.maintenance AS maintenance,
       pn.prd_cost AS cost,
       pn.prd_line As product_line,
       pn.prd_start_dt AS product_start_date
FROM   silver.crm_prd_info AS pn 
LEFT JOIN silver.erp_px_cat_g1v2 AS pm
ON pn.cat_id = pm.id
WHERE  prd_end_dt IS NULL;                          -- filter out most recent (current) product start date



 


-----------------------------------------------------------------------------------------------------
-- Create Fact: gold.fact_sales
-----------------------------------------------------------------------------------------------------

CREATE VIEW  gold.fact_sales AS
SELECT            sd.sls_ord_num AS order_number,
                  pr.product_key,
                  cu.customer_key,
                  sd.sls_order_dt AS order_date,
                  sd.sls_ship_dt AS shipping_date,
                  sd.sls_due_dt AS due_date,
                  sd.sls_sales AS sales_amount,
                  sd.sls_quantity AS quantity,
                  sd.sls_price As price
                  
FROM   silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.customer_id;



----------------------------------------------------------------------------------------------
--check the views created

select * from gold.dim_customers
select * from gold.dim_products
select * from gold.fact_sales

----------------------------------------------------------------------------------------------
