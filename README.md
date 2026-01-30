# Data Warehouse and Analytics Project

Welcome to the ** Data Warehouse and Analytics Project** repository.
This project uses industry best pratices in data engineering and analytics in building a modern data warehouse with SQL Server, including ETL processes, data modeling and analytics. It demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights.

-----------------------------------------------------------------------------------------------------------------------------------------------------
## Project Overview

This project involves the following:
1. Data Architecture - designing a modern data warehouse using the medallion architecture bronze, silver and gold layers
2. ETL Pipelines - Extracting Transforming and Loading data from the source systems into the warehouse
3. Data Modeling - Developing fact and dimension tables optimized for analytical queries
4. Analytics & Reporting - Creating SQL based reports and dashboards for actionable insights

This repository demonstrates Skills/ expertise in the following areas:
- SQL Development
- Data Architecture
- Data Engineering
- ETL Pipeline Development
- Data modeling
- Data Analytics

-----------------------------------------------------------------------------------------------------------------------------------------------------
## Important Links & Tools 

- [Datasets:](https://cnn.com) Access is free for all the project datasets [csv files] 
- [SQL Server Express: ](https://www.microsoft.com/en-us/download/details.aspx?id=101064) Lightweight server for hosting SQL database
- [SQL Server Management Studio (SSMS):](https://learn.microsoft.com/en-us/ssms/install/install) GUI for managing and interacting with the databases
- [Git repository:](https://github.com/) Setup a Git account and repository to manage, version, and collaborate on your code efficiently
- [DrawIO:](https://app.diagrams.net/) Online diagramming application for creating flowcharts, UML, entity relation, network diagrams, mockups and more
- [Notion: ](https://app.diagrams.net/) All-in-one tool for project management and organization
- https://www.markdownguide.org/basic-syntax/
- https://guides.github.com/features/mastering-markdown/
- https://www.flaticon.com/
- https://www.readmecodegen.com/file-tree/github-file-tree-visualizer

-----------------------------------------------------------------------------------------------------------------------------------------------------
## Project Requirements

### Building the Data Warehouse

#### Objective
Develop a modern data warehouse with SQL Server, including ETL processes, data modeling to consolidate sales data thus enabling analytical reporting and informed decision making.

**Data Sources:** Import data from two source systems (CRM and ERP) provided as csv files
**Data Quality:** Cleanse and resolve data quality issues prior to analysis
**Integration:** Combine both sources into a single, user friendly data model designed for analytical queries
**Scope:** Focus on the latest dataset only - historization of details not required
**Documentation:** Provide clear documentation of the data to support business stakeolders and analytics teams

-----------------------------------------------------------------------------------------------------------------------------------------------------
## BI: Analytics and Reporting

#### Objective

**- Customer Behaviour**<br>
**- Product Performance**<br>
**- Sales Trends**<br>

These insights empower stakeholders with key business metrics, enablingstrateic decision making

-----------------------------------------------------------------------------------------------------------------------------------------------------
## Data Architecture

The data architecture for this project follows the Medallion Architecture **Bronze, Silver** and **Gold layers**

<img width="1237" height="818" alt="Image" src="https://github.com/user-attachments/assets/76a5444e-f226-41ba-a695-e30111653dbe" />


-----------------------------------------------------------------------------------------------------------------------------------------------------
## Repository Structure


```

sql-data-warehouse-projects/
    ├── datasets/                                  # Raw data sets used for the project (CRM and ERP)
    ├── documents/                                 # Key documents used in this project
    │   ├── Data Flow Diagram_DrawIO.drawio        # Data flow diagram for this project in draw.io format
    │   ├── Data Integration Model_DrawIO.drawio   # Data integration model for this project depicting related fields in differnt bronze layer tables used for joining
    │   ├── Data Mart.drawio                       # Data mart (star schema) showing database relationship and primary keys
    │   ├── Data_Catalogue                         # Data catalogue of the different columns in the dimension and fact tables with description
    │   ├── Project Architecture_DrawIO.pdf        # Project architecture depicting the bronze, silver and gold layers in draw.io format
    ├── images/                                    # image folder
    │   ├── external-link.png                      # Sample image 
    ├── scripts/                                   # SQL scripts used for extraction and transformation
    │   ├── 01_Bronze/                             # Scripts for extracting and loading raw data
    │   ├── 02_Silver/                             # Scripts for cleaning and transforming data
    │   ├── 03_Gold/                               # Scripts for creating analytical models
    ├── tests/
    │   ├── CleanData_Quality Checks.SQL           # Scripts for testing & quality checks in Silver and bronze layers 
    │   └── GoldData_Quality Checks.SQL            # Scripts for testing & quality checks in Gold 
    └── README.md                                  # Project overview and instructions
    └── LICENSE.md                                 # License information for the repository


```

-----------------------------------------------------------------------------------------------------------------------------------------------------
## License

This project is licensed under the MIT license. You are therefore free to use, share and modify with proper attribution.


-----------------------------------------------------------------------------------------------------------------------------------------------------
# About Me

Hello There! Iam Jacob Ogogo (Jake)

