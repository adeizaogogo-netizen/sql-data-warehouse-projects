/* 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                                               CLEAN,TRANSFORM AND LOAD ALL CRM TABLES 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

This stored procedure below loads cleaned and transformed bronze schema tables into the corresponding 'silver' schema tables.  
For each table the script
i. Truncates the silver table before loading data
ii. Uses the INSERT TABLE function to load data from the bronze tables into the silver tables

Note that a truncate statement e.g. "TRUNCATE TABLE silver.crm_cust_info" is included at the 
beginning of the load code to ensure that exisiting table is emptied before inserting entire
data (every time we run the load code)

The load code for the silver layer is saved as a stored procedure: "silver.load_silver". This
is executed anytime we want to refresh/ upload data into the database.

Stored procedure: "silver.load_silver" 
- Parameters: NONE
  The Stored procedure does not accept any parameters or return any values. 
- Details of the execution is displayed in the messages


*/


USE DataWarehouse
GO
-- Execute stored procedure "silver.load_silver" to load ALL the tables

EXEC silver.load_silver;
-----------------------------------------------------------------------------------------------------------------------------------


-- Wrap the load code as a stored procedure "silver.load_silver"

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    DECLARE @start_time AS DATETIME, @end_time AS DATETIME, @batch_start_time AS DATETIME, @batch_end_time AS DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===================================================================';
        PRINT 'Loading Silver Layer';
        PRINT '===================================================================';
        PRINT '--------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '--------------------------------------------------------------------';

/*
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.crm_cust_info'  AND LOAD CLEANED DATA INTO 'silver.crm_cust_info'
------------------------------------------------------------------------------------------------------------------------------------

CHECK FOR NULLS OR DUPLICATES IN PRIMARY KEY 'cst_id' (Expectation NO RESULT)
RANK PRIMARY KEY VALUES THAT HAVE DUPLICATES BY CREATION DATE FROM 'cst_id' AND SELECT ONLY MOST RECENT FOR TRANSFER TO SILVER LAYER 
TABLE 'silver.crm_cust_info'
CHECK FOR UNWANTED SPACES IN THE TEXT COLUMNS (NVARCHAR COLUMNS > cst_firstname, cst_lastname, cst_marital_status, cst_gndr)> 
EXPECTATION: NO RESULT 
REPLACE THE TEXT VALUES IN COLUMNS THAT HAVE UNWANTED SPACES WITH THEIR TRIMMED VALUES USING 'TRIM' COMMAND
DATA STANDARDIZATION AND CONSISTENCY: CHECK FOR DISTINCT VALUES IN EACH COLUMN 'cst_marital_status' and 'cst_gndr'  COLUMNS. 
IN OUR DATA WAREHOUSE, WE AIM TO STORE CLEAR AND MEANINGFUL VALUES RATHER THAN USING ABBREVIATED TERMS
REPLACE THE 'F' WITH 'Female', 'M' WITH 'Male' AND 'NULL' WITH 'n/a' USING 'CASE-WHEN-THEN-ELSE-END' FUNCTION.
UPPER (cst_gndr) IN CASE THERE ARE LOWERCASE DATA
CHECK (VERIFY) THE CLEANED DATA IN LOADED TABLE IN SILVER LAYER

*/
SET @start_time = GETDATE();
PRINT '>> Truncating Table: silver.crm_cust_info  ';
TRUNCATE TABLE silver.crm_cust_info;                --Truncate the Table to empty it before Inserting updated data into the table 
PRINT '>> Inserting Data Into Table: silver.crm_cust_info ';
INSERT INTO silver.crm_cust_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date)

SELECT cst_id,
       cst_key,
       TRIM(cst_firstname) AS cst_firstname,
       TRIM(cst_lastname) AS cst_lastname,
       CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a' END AS cst_marital_status,
       CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a' END AS cst_gndr,
       cst_create_date
  FROM (   SELECT *,
                  ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
             FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL) AS t
 WHERE flag_last = 1;
 

SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';


/*
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.crm_prd_info'  AND LOAD CLEANED DATA INTO 'silver.crm_prd_info'
------------------------------------------------------------------------------------------------------------------------------------

CHECK FOR NULLS OR DUPLICATES IN PRIMARY KEY 'prd_id' (Expectation NO RESULT)
EXTRACT CATALOGUE ID FROM PRD_KEY AS CAT_ID
REPLACE '-' WITH '_' IN EXTRACTED DATA
FILTER OUT UNMATCHED DATA AFTER APPLYING TRANSFORMATION ('CO_PE' CATEGORY NOT IN 'erp_px_cat_g1v2'
EXTRACT  'prd_key' FROM 'prd_key'
CHECK FOR UNWANTED SPACES IN PRODUCT NAME 'prd_nm'
CHECK FOR NULL AND NEGATIVE NUMBERS IN 'prd_cost'. NO NEGATIVE COSTS BUT REPLACE NULL WITH 0 USING 'ISNULL' FUNCTION
CHECK  DISTINCT VALUES OF 'prd_line'; 
REPLACE LETTERS WITH DESCRIPTIVE WORDS UDING 'TRIM(UPPER())' & 'CASE WHEN THEN ELSE END' FUNCTIONS
CHECK THE START & END DATE RELATIONSHIPS ( WHERE  prd_start_dt> prd_end_dt) TOO MANTY LINES >> IGNORE END DATE/ DERIVE NEW END DATE
NEW END DATE IS THE START DATE OF THE NEXT RECORD (USE LEAD WINDOW FUNCTION)  -1 DAY (PARTITION BY PRODUCT KEY)
GO TO SILVER.CRM_PRD_INFO DDL AND UPDATE THE SCHEMA (ADD NEW COLUMN cat_id AND UPDATE TYPE OF prd_start_dt & prd_end_dt TO DATE AND EXECUTE
 */                               
SET @start_time = GETDATE();
PRINT '>> Truncating Table: silver.crm_prd_info   ';
TRUNCATE TABLE silver.crm_prd_info;                     --Truncate the Table to empty it before Inserting updated data into the table
PRINT '>> Inserting Data Into Table: silver.crm_prd_info  ';
INSERT INTO silver.crm_prd_info(
                                prd_id,
                                cat_id,
                                prd_key,
                                prd_nm,
                                prd_cost,
                                prd_line,
                                prd_start_dt,
                                prd_end_dt
                                )

SELECT prd_id,
       REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
       SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
       TRIM(prd_nm) AS prd_nm,
       ISNULL(prd_cost, 0) AS prd_cost,
       CASE
            WHEN TRIM(UPPER(prd_line)) = 'M' THEN 'Mountain'
            WHEN TRIM(UPPER(prd_line)) = 'R' THEN 'Road'
            WHEN TRIM(UPPER(prd_line)) = 'S' THEN 'Other Sales'
            WHEN TRIM(UPPER(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a' END AS prd_line,
       CAST(prd_start_dt AS DATE) AS prd_start_dt,
       CAST(LEAD(prd_start_dt, 1) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
  FROM bronze.crm_prd_info
  SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';


 
/* 
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.crm_sales_details bronze.'  AND LOAD CLEANED DATA INTO 'silver.crm_sales_details'
------------------------------------------------------------------------------------------------------------------------------------

CHECK FOR UNWANTED SPACES IN NVARCHAR COLUMNS 'sls_ord_num' AND 'sls_prd_key' FOR UNWANTED SPACES >> EXPECTATION: NO RESULT
CHECK FOR INSTANCES OF 'sls_prd_key' NOT IN THE prd_key IN THE CLEANED silver.crm_prd_info >> EXPECTATION NO RESULT
CHECK FOR INSTANCES OF 'sls_cust_id' NOT IN THE 'cst_id' IN THE CLEANED silver.crm_cust_info >> EXPECTATION NO RESULT
DOING ABOVE CONFIRMS WE CAN JOIN THE TWO TABLES WITHOUT ANY ISSUES (SEE DATA INTEGRATION MODEL @NOTION) SCRIPT BELOW
CHECK FOR INVALID DATES >> 0 OR NEGATIVE, IF 0 THEN CONVERT TO NULL >. SCRIPT BELOW
CONVERT DATE CURRENTLY TEXT TO VAECHAR THEN TO DATE FORMAT. REPEAT FOR sls_ship_dt AND sls_due_dt
CHECK THAT THE ORDER DATE EARLIER THAN THE SHIPPING DATE AND THE DUE DATE
CHECK FOR NEGATIVE, ZERO AND INCORRECT VALUES OF  'sls_sales', 'sls_quantity', 'sls_price' AND APPLY RULES
RULES: 
    > IF 'sls_sales' IS NEGATIVE, ZERO OR NULL, DERIVE IT USING 'sls_quantity' & 'sls_price'
    > IF PRICE IS ZERO OR NULL CALCULATE IT USING 'sls_sales' & sls_quantity' 
    > IF PRICE IS NEGATIVE, CONVERT IT TO A POSITIVE VALUE
*/

SET @start_time = GETDATE();
PRINT '>> Truncating Table:  silver.crm_sales_details  ';

TRUNCATE TABLE silver.crm_sales_details;                      --Truncate the Table to empty it before Inserting updated data into the table
PRINT '>> Inserting Data Into Table: silver.crm_sales_details  ';

INSERT INTO silver.crm_sales_details (sls_ord_num,
                                      sls_prd_key,
                                      sls_cust_id,
                                      sls_order_dt,
                                      sls_ship_dt,
                                      sls_due_dt,
                                      sls_sales,
                                      sls_quantity,
                                      sls_price)
SELECT TRIM(sls_ord_num) AS sls_ord_num,
       TRIM(sls_prd_key) AS sls_prd_key,
       sls_cust_id,
       CASE
            WHEN sls_order_dt = 0
              OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)END AS sls_order_dt,
       CASE
            WHEN sls_ship_dt = 0
              OR LEN(sls_ship_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)END AS sls_ship_dt,
       CASE
            WHEN sls_due_dt = 0
              OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)END AS sls_due_dt,
       CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales END AS sls_sales,
       sls_quantity,
       CASE
            WHEN sls_price IS NULL
              OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price END AS sls_price
  FROM bronze.crm_sales_details;

SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';


/*
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                                               CLEAN,TRANSFORM AND LOAD ALL ERP TABLES 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*/

PRINT '--------------------------------------------------------------------';
PRINT 'Loading ERP Tables';
PRINT '--------------------------------------------------------------------';

 

/*
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.erp_cust_az12 ' TABLE  AND LOAD CLEANED DATA INTO 'silver.erp_cust_az12'  TABLE
------------------------------------------------------------------------------------------------------------------------------------
*/

SET @start_time = GETDATE();
PRINT '>> Truncating Table:  silver.erp_cust_az12   ';

TRUNCATE TABLE silver.erp_cust_az12;        --Truncate the Table to empty it before Inserting updated data into the table
PRINT '>> Inserting Data Into Table:  silver.erp_cust_az12  ';
INSERT INTO silver.erp_cust_az12 (cid,
                                  bdate,
                                  gen)
SELECT 
       CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, len(cid)) ELSE cid END AS cid,
       CASE
            WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
       CASE
            WHEN UPPER(TRIM(gen)) IN ( 'F', 'FEMALE' ) THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ( 'M', 'MALE' ) THEN 'Male'
            ELSE 'n/a' END AS gen
FROM bronze.erp_cust_az12;

SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';

/*
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.erp_loc_a101' TABLE  AND LOAD CLEANED DATA INTO 'silver.erp_loc_a101'  TABLE
------------------------------------------------------------------------------------------------------------------------------------
*/
SET @start_time = GETDATE();
PRINT '>> Truncating Table:  silver.erp_loc_a101  ';

TRUNCATE TABLE silver.erp_loc_a101;            --Truncate the Table to empty it before Inserting updated data into the table
PRINT '>> Inserting Data Into Table: silver.erp_loc_a101  ';

INSERT INTO silver.erp_loc_a101 (cid,
                                 cntry)
SELECT REPLACE(cid, '-', '') AS cid,
       CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ( 'US', 'USA' ) THEN 'United States'
            WHEN TRIM(cntry) IN ( '', 'NULL' ) THEN 'n/a'
            ELSE TRIM(cntry) END AS cntry
  FROM bronze.erp_loc_a101;

  SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';



  /*
------------------------------------------------------------------------------------------------------------------------------------
CLEAN & TRANSFORM 'bronze.erp_px_cat_g1v2' TABLE  AND LOAD CLEANED DATA INTO 'silver.erp_px_cat_g1v2'  TABLE
------------------------------------------------------------------------------------------------------------------------------------
*/
SET @start_time = GETDATE();
PRINT '>> Truncating Table:  silver.erp_px_cat_g1v2   ';

TRUNCATE TABLE silver.erp_px_cat_g1v2;         --Truncate the Table to empty it before Inserting updated data into the table
PRINT '>> Inserting Data Into Table: silver.erp_px_cat_g1v2   ';
INSERT INTO silver.erp_px_cat_g1v2 (id,
                                    cat,
                                    subcat,
                                    maintenance)
SELECT id,
       cat,
       subcat,
       maintenance
  FROM bronze.erp_px_cat_g1v2;

SET @end_time = GETDATE();
PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
PRINT '>> ---------------';
SET @batch_end_time = GETDATE();

        PRINT '===================================================================';
        PRINT 'Loading of Silver Layer is completed';
        PRINT '>> Total Batch Load Duraton: ' + CAST (DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
        PRINT '===================================================================';
END TRY
    BEGIN CATCH
        PRINT '===================================================================';
        PRINT 'ERROR OCCURRED WHILE LOADING SILVER LAYER ';
        PRINT 'Error Message ' + ERROR_MESSAGE();
        PRINT 'Error Message ' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message ' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT '===================================================================';
    END CATCH
END

