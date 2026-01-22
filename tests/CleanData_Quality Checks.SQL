


/*
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                             SCRIPTS FOR CLEANING & TRANSFORMING RAW DATA 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*/
USE DataWarehouse
GO

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--NOTE TO TRUNCATE EACH TABLE TO EMPTY IT BEFORE INSERTING UPDATED DATA IN THE TABLE
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


SELECT cst_id,
       cst_key,
       cst_firstname,
       cst_lastname,
       cst_marital_status,
       cst_gndr,
       cst_create_date
FROM   DataWarehouse.bronze.crm_cust_info;
------------------------------------------------------------------------------------------------------------------------------------
--CHECK FOR NULLS OR DUPLICATES IN PRIMARY KEY 'cst_id' (Expectation NO RESULT)
SELECT   cst_id,
         COUNT(*) AS id_count
FROM     bronze.crm_cust_info
GROUP BY cst_id
HAVING   COUNT(cst_id) > 1
         OR cst_id IS NULL;
------------------------------------------------------------------------------------------------------------------------------------
--HANDLE DUPLICATES & NULLS IN PRIMARY KEY IDENTIFIED ABOVE BY RANKING PRIMARY KEY VALUES THAT HAVE DUPLICATES BY CREATION DATE FROM 'cst_id' AND SELECT ONLY MOST RECENT 

SELECT *,
        ROW_NUMBER() OVER               --Assigns:1 to the most recent record per cst_id, 2, 3, ... to older records
        (PARTITION BY cst_id            --Groups rows by customer ID
        ORDER BY cst_create_date DESC)  --Orders each customer’s records from newest to oldest
        AS flag_last                    --Identifies the latest record per customer
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
 
------------------------------------------------------------------------------------------------------------------------------------
--CHECK FOR UNWANTED SPACES IN THE TEXT COLUMNS (NVARCHAR COLUMNS > cst_firstname, cst_lastname, cst_marital_status, cst_gndr)> EXPECTATION: NO RESULT 

SELECT * FROM bronze.crm_cust_info
WHERE TRIM(cst_firstname) != cst_firstname;

TRIM(cst_firstname) AS cst_firstname    --Use 'TRIM' function to remove unwanted spaces. Repeat for all text columns  
TRIM(cst_lastname) AS cst_lastname      --Use 'TRIM' function to remove unwanted spaces. 
 
------------------------------------------------------------------------------------------------------------------------------------
--DATA STANDARDIZATION AND CONSISTENCY: CHECK FOR DISTINCT VALUES IN EACH COLUMN 'cst_marital_status' and 'cst_gndr'  COLUMNS. 
--We aim to store clear & meaninful vales rather than abbreviated terms; 
--Get Distinct values for 'cst_marital_status' and 'cst_gndr'

SELECT DISTINCT cst_marital_status      
FROM   bronze.crm_cust_info;    

--Replace the 'F' with 'Female', 'F' with 'Male' and 'NULL' with 'n/a' using 'CASE-WHEN-THEN-ELSE-END' function
CASE
    WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'   
    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'  
    ELSE 'n/a' END AS cst_marital_status


--CHECK (VERIFY) THE CLEANED DATA IN LOADED TABLE IN SILVER LAYER

SELECT * FROM   silver.crm_cust_info;--Run all the above queries on silver.crm_cust_info >>EXPECTATION NO RESULT 



--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

SELECT            prd_id,
                  prd_key,
                  prd_nm,
                  prd_cost,
                  prd_line,
                  prd_start_dt,
                  prd_end_dt
FROM   DataWarehouse.bronze.crm_prd_info;

------------------------------------------------------------------------------------------------------------------------------------
--EXTRACT CATALOGUE ID FROM PRD_KEY AS CAT_ID AFTER CHECKING THE RELATIONSHIP IN DATA INTEGRATION MODEL(DRAW.IO)
--PRD_KEY RELATED TO crm_sales_details AND erp_px_cat_g1v2

SUBSTRING(prd_key, 1, 5)                                --Extract catalogue ID from 'prd_key' as 'cat_id' 
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id   --Replace '-' with '_' # match column 'id' in 'erp_px_cat_g1v2' in later joins

------------------------------------------------------------------------------------------------------------------------------------
--Find data in already transformed 'prd_key' that does not match 'id' in erp_px_cat_g1v2
SELECT *
FROM   bronze.crm_prd_info
WHERE  REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')       --Already transformed data
NOT IN (SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2)  --Matched data in erp_px_cat_g1v2 from Data Integration Model ;

------------------------------------------------------------------------------------------------------------------------------------
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key          --Leave the remaining data atfter extraction as  'prd_key'
                                                        --Find data remaining data after extraction 'prd_key' that does not match 'prd_key' in crm_sales_details (PRODUCTS WITHOUT ORDERS)
SELECT  SUBSTRING(prd_key, 7, LEN(prd_key)) 
FROM   bronze.crm_prd_info
WHERE   SUBSTRING(prd_key, 7, LEN(prd_key))             --remaining data atfter extraction
NOT IN (SELECT DISTINCT sls_prd_key FROM bronze.crm_sales_details)  --Matched data in erp_px_cat_g1v2 from Data Integration Model ;

------------------------------------------------------------------------------------------------------------------------------------
-- Check for NULl or negative cost 'prd_cost'
SELECT *
FROM  bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

--Replace all NULL costs with 0 using 'ISNULL' function
ISNULL(prd_cost, 0) AS prd_cost

------------------------------------------------------------------------------------------------------------------------------------
--DATA STANDARDIZATION AND CONSISTENCY:CHECK  DISTINCT VALUES OF 'prd_line' and replace with non abbreviated values; 
SELECT DISTINCT prd_line      
FROM   bronze.crm_prd_info;  

------------------------------------------------------------------------------------------------------------------------------------
--Check for invalid date orders: end date must be greater than start date
SELECT *
FROM   bronze.crm_prd_info
where  prd_end_dt <prd_start_dt

--Analyze and ensure that end date is later than start date using the LEAD window function on the prd_start_dt
--Change the date prd_start_dt field from DATETIME to DATE format
SELECT prd_key, CAST(prd_start_dt AS DATE) AS prd_start_dt, 
       CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM   bronze.crm_prd_info

--Change the date prd_start_dt field from DATETIME to DATE format

------------------------------------------------------------------------------------------------------------------------------------
--GO TO SILVER.CRM_PRD_INFO DDL AND UPDATE THE SCHEMA (ADD NEW COLUMN cat_id AND UPDATE TYPE OF prd_start_dt & prd_end_dt TO DATE AND 
--EXECUTE
------------------------------------------------------------------------------------------------------------------------------------


 
SELECT sls_ord_num,
       sls_prd_key,
       sls_cust_id,
       sls_order_dt,
       sls_ship_dt,
       sls_due_dt,
       sls_sales,
       sls_quantity,
       sls_price
FROM   DataWarehouse.bronze.crm_sales_details;


--Check for unwanted spaces in nvarchar columns 'sls_ord_num' and 'sls_prd_key' for unwanted spaces >> expectation: no result
SELECT * FROM bronze.crm_sales_details
WHERE TRIM(sls_prd_key) != sls_prd_key;

--Check that product key for every transaction in bronze.crm_sales_details can be joined to prd_key in already cleaned silver.crm_prd_info
--Repeat for sls_cust_id. This ensures that we can join tables crm_sales_details and crm_prd_info without issues
SELECT sls_prd_key
FROM   bronze.crm_sales_details
WHERE  sls_prd_key NOT IN (SELECT sls_prd_key
                             FROM   silver.crm_prd_info);


--CAST integer date 'sls_order_dt' first to to varchar then CAST to date
CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)

--CHECK FOR INVALID DATES >> 0 OR NEGATIVE, IF 0 THEN CONVERT TO NULL >. SCRIPT BELOW
            SELECT NULLIF (sls_due_dt, 0) AS sls_due_dt
            FROM   bronze.crm_sales_details
            WHERE  sls_due_dt <= 0
                   OR LEN(sls_due_dt) != 8
                   OR sls_due_dt > 20500101
                   OR sls_due_dt < 19000101;

/*
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                             SCRIPTS FOR CHECKING HEALTH OF TABLE AFTER LOADING THE CLEANED TRANSFORMED DATA
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*/
 
     SELECT * FROM silver.crm_prd_info
 ------------------------------------------------------------------------------------------------------------------------------------
 -- Check for nulls or duplicates of the Primary Key
 -- Expectation : No result
 SELECT   prd_id,
         COUNT(*) AS id_count
FROM     silver.crm_prd_info
GROUP BY prd_id
HAVING   COUNT(*) > 1
         OR prd_id IS NULL;


-- Check for nulls or duplicates of the Primary Key
-- Expectation : No result
SELECT * FROM bronze.crm_cust_info
WHERE TRIM(cst_firstname) != cst_firstname;

-- Check for unwanted spaces in the nvarchar columns

SELECT * FROM silver.crm_prd_info
WHERE TRIM(prd_line) != prd_line ;

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM   silver.crm_prd_info;

--Check for Invalid Date Orders: end date must be greater than start date
SELECT *
FROM   silver.crm_prd_info
where  prd_end_dt <prd_start_dt

-- Ensure that all customer id from 'erp_cust_az12' is contained in the cleaned 'silver.crm_cust_info' table and both tables can be joined
SELECT * FROM
(SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, len(cid)) ELSE cid END AS cid,
       bdate,
       gen
FROM   bronze.erp_cust_az12) t
WHERE  cid NOT IN (SELECT DISTINCT cst_key
                   FROM   silver.crm_cust_info);


-- Check for birthdays that are too old or in the future/ replace the impossible ones (future date) with NULL
  SELECT bdate FROM bronze.erp_cust_az12 WHERE bdate < '1925-01-01' OR bdate > GETDATE()
