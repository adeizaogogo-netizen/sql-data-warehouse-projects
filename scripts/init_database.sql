
/*
========================================================================================================================
Create Database and Schemas
========================================================================================================================
Script Purpose:
    This script creates a new database names 'DataWarehouse' after checking if it already exists. If it already exists, 
    it is dropped and recreated. Additionally, the script sets up three schemas within the database: 'bronze', 'silver' 
    and 'gold'.
WARNING:
    Running this script will delete the 'DataWarehouse' database if it already exists. All data in the database will be 
    permanently deleted! Proceed with caution and backup data before running this script.
*/

USE master;
GO

-- Drop 'DataWarehouse' database if it is already exisiting  
IF EXISTS (SELECT 1
           FROM   sys.databases
           WHERE  name = 'DataWarehouse')
    BEGIN
        ALTER DATABASE DataWarehouse
            SET SINGLE_USER 
            WITH ROLLBACK IMMEDIATE;
        DROP DATABASE DataWarehouse;
    END;

GO

-- create new 'DataWarehouse' database
CREATE DATABASE DataWarehouse;

-- switch to project 'DataWarehouse' database
USE DataWarehouse;
GO

-- create schemas for the database corresponding to the different layers bronze/ silver/ gold
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
 
