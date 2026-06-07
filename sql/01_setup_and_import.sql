-- =========================================================================
-- 01_setup_and_import.sql
-- Project: Amazon Delivery Performance & Logistics Analysis
-- Purpose: Initial database schema creation, CSV import, and data type setup.
-- Run order: This file should be executed FIRST.
-- 
-- Notes:
--   - LOAD DATA LOCAL INFILE is used for fast bulk import. Requires
--     local_infile=1 on both server and client side (set in Workbench
--     connection: Advanced -> Others -> OPT_LOCAL_INFILE=1).
--   - File paths assume the CSV is stored at the path below. Adjust to
--     match your local environment.
--   - Initial data types are intentionally conservative — dates and times
--     are loaded as VARCHAR first because the source CSV uses DD/MM/YYYY
--     format which MySQL cannot parse natively. They are converted to
--     proper DATE / TIME types in 02_data_cleaning.sql after format fixes.
--   - Coordinates use DOUBLE for adequate precision (FLOAT loses accuracy
--     beyond ~6 decimal places, which matters for GPS data).
-- =========================================================================

-- Create the database
CREATE DATABASE amazon_delivery;
USE amazon_delivery;

-- -------------------------------------------------------------------------
-- Create the deliveries table
-- -------------------------------------------------------------------------
CREATE TABLE deliveries (
    Order_ID VARCHAR(50),
    Agent_Age INT,
    Agent_Rating FLOAT,
    Store_Latitude DOUBLE,
    Store_Longitude DOUBLE,
    Drop_Latitude DOUBLE,
    Drop_Longitude DOUBLE,
    Order_Date VARCHAR(20),     -- Loaded as VARCHAR (source format: DD/MM/YYYY)
    Order_Time VARCHAR(20),     -- Loaded as VARCHAR; converted to TIME in cleaning
    Pickup_Time VARCHAR(20),    -- Loaded as VARCHAR; converted to TIME in cleaning
    Weather VARCHAR(50),
    Traffic VARCHAR(50),
    Vehicle VARCHAR(50),
    Area VARCHAR(50),
    Delivery_Time INT,
    Category VARCHAR(50)
);

-- -------------------------------------------------------------------------
-- Import the source CSV
-- Expected rows: ~43,739
-- Source: https://www.kaggle.com/datasets/sujalsuthar/amazon-delivery-dataset
-- -------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'D:/study/Portfolio/Delivery Performance & Logistics Analysis/amazon_delivery_Raw.csv'
INTO TABLE deliveries
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- -------------------------------------------------------------------------
-- Verify import
-- -------------------------------------------------------------------------
SELECT COUNT(*) AS total_rows FROM deliveries;
-- Expected: ~43,739
