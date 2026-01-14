/*
This stored procedure below loads into the 'bronze' schema from externally loacted (cloud) csv files 
and inserts into the corresponding tables. 
It performs the following actions per table
i. Truncates the bronze table before loading data
ii. Uses the BULK INSERT command to load data from the csv files to the bronze tables

Note that a truncate statement e.g. "TRUNCATE TABLE bronze.crm_cust_info" is included at the 
beginning of the load code to ensure that exisiting table is emptied before inserting entire
data (every time we run the load code)

The code to load the bronze layer is saved as a stored procedure: "bronze.load_bronze". This
is executed anytime we want to refresh/ upload data into the database.

Stored procedure: "bronze.load_bronze" 
- Parameters: NONE
  The Stored procedure does not accept any parameters or return any values. 
- Details of the execution is displayed in the meassages

*/

-- Ensure you are operating in teh right database environment
USE DataWarehouse;

-- Execute stored procedure "bronze.load_bronze" to load ALL the tables
EXECUTE bronze.load_bronze ;

-- The stored procedure "bronze.load_bronze" is defined below

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    DECLARE @start_time AS DATETIME, @end_time AS DATETIME, @batch_start_time AS DATETIME, @batch_end_time AS DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===================================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '===================================================================';
        PRINT '--------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '--------------------------------------------------------------------';
        --bronze.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Inserting Data Into Table: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';

        --bronze.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Data Into Table: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';

        --bronze.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Data Into Table: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';


        PRINT '--------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '--------------------------------------------------------------------';

        --bronze.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Inserting Data Into Table: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12 FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';

        --bronze.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT '>> Inserting Data Into Table: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101 FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';

        --bronze.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into Table: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2 FROM 'C:\Users\Jake\OneDrive\Jake_PS\2026\Data Analysis_Science\SQL Bootcamp Playlist (2025) - Zero to Hero\02_sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '>> Load Duraton: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> ---------------';
        SET @batch_end_time = GETDATE();

        PRINT '===================================================================';
        PRINT 'Loading of Bronze Layer is completed';
        PRINT '>> Total Batch Load Duraton: ' + CAST (DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
        PRINT '===================================================================';
    END TRY
    BEGIN CATCH
        PRINT '===================================================================';
        PRINT 'ERROR OCCURRED WHILE LOADING BRONZE LAYER ';
        PRINT 'Error Message ' + ERROR_MESSAGE();
        PRINT 'Error Message ' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message ' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT '===================================================================';
    END CATCH
END

