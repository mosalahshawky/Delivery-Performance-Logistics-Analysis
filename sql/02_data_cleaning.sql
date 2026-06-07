-- =========================================================================
-- 02_data_cleaning.sql
-- Project: Amazon Delivery Performance & Logistics Analysis
-- Purpose: Audit and clean the imported data. Convert 'NaN' strings to NULL,
--          trim trailing whitespace, fix date format, construct proper
--          DATETIME columns with cross-midnight pickup logic, and build the
--          base cleaning view.
-- Run order: Execute SECOND, after 01_setup_and_import.sql.
-- 
-- Key data quality findings discovered during this phase:
--   - 91 rows have 'NaN' in Order_Time, Weather, and Traffic (same 91 rows).
--   - 54 rows have NULL Agent_Rating.
--   - 3,505 rows have coordinates near (0,0) — "Null Island" placeholder
--     for missing GPS data (these are filtered in 03_features_and_geo.sql).
--   - Categorical columns have trailing whitespace (e.g., "motorcycle ").
--   - 828 rows initially appeared to have pickup BEFORE order — all are
--     cross-midnight cases (HOUR=23 order, HOUR=0 pickup). Handled by
--     building a proper DATETIME with conditional date adjustment.
-- =========================================================================

USE amazon_delivery;

-- =========================================================================
-- STEP 1 — NULL AUDIT (before cleaning)
-- Quantify the size of each data quality issue before fixing it.
-- =========================================================================
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Agent_Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN TRIM(Order_Time) = 'NaN' THEN 1 ELSE 0 END) AS nan_order_time,
    SUM(CASE WHEN Weather = 'NaN' THEN 1 ELSE 0 END) AS nan_weather,
    SUM(CASE WHEN TRIM(Traffic) = 'NaN' THEN 1 ELSE 0 END) AS nan_traffic,
    SUM(CASE WHEN Drop_Latitude BETWEEN -0.1 AND 0.1 
              AND Drop_Longitude BETWEEN -0.1 AND 0.1 THEN 1 ELSE 0 END) AS null_island_drops,
    SUM(CASE WHEN Store_Latitude BETWEEN -0.1 AND 0.1 
              AND Store_Longitude BETWEEN -0.1 AND 0.1 THEN 1 ELSE 0 END) AS null_island_stores
FROM deliveries;

-- Confirm all 91 NaN rows are the same rows (verified hypothesis)
SELECT COUNT(*) 
FROM deliveries
WHERE TRIM(Order_Time) = 'NaN' AND Weather = 'NaN' AND TRIM(Traffic) = 'NaN';
-- Expected: 91 (confirms NaN values cluster in the same incomplete records)

-- =========================================================================
-- STEP 2 — Convert 'NaN' strings to true NULL values
-- Using TRIM() in WHERE catches both 'NaN' and 'NaN ' variants.
-- =========================================================================
UPDATE deliveries SET Order_Time = NULL WHERE TRIM(Order_Time) = 'NaN';
UPDATE deliveries SET Weather    = NULL WHERE TRIM(Weather)    = 'NaN';
UPDATE deliveries SET Traffic    = NULL WHERE TRIM(Traffic)    = 'NaN';

-- =========================================================================
-- STEP 3 — Strip trailing whitespace from categorical columns
-- Source CSV has values like "motorcycle ", "Urban ", "Pet Supplies ".
-- Without trimming, GROUP BY treats these as distinct from their clean
-- counterparts — a silent bug that produces inflated category counts.
-- =========================================================================
UPDATE deliveries SET Vehicle  = TRIM(Vehicle);
UPDATE deliveries SET Category = TRIM(Category);
UPDATE deliveries SET Traffic  = TRIM(Traffic);
UPDATE deliveries SET Weather  = TRIM(Weather);
UPDATE deliveries SET Area     = TRIM(Area);

-- =========================================================================
-- STEP 4 — Convert Order_Date from DD/MM/YYYY (text) to proper DATE type
-- Two-step process: first reformat values via STR_TO_DATE, then ALTER type.
-- The WHERE clause makes this idempotent (safe to re-run).
-- =========================================================================
UPDATE deliveries
SET Order_Date = STR_TO_DATE(Order_Date, '%d/%m/%Y')
WHERE Order_Date LIKE '%/%';

ALTER TABLE deliveries MODIFY Order_Date DATE;

-- =========================================================================
-- STEP 5 — Convert Order_Time and Pickup_Time to TIME type
-- Source values are already in HH:MM:SS format, so ALTER alone works
-- (no STR_TO_DATE needed). Note: must run AFTER 'NaN' -> NULL conversion
-- in Step 2, otherwise this ALTER fails on the 91 malformed rows.
-- =========================================================================
ALTER TABLE deliveries 
MODIFY Order_Time TIME,
MODIFY Pickup_Time TIME;

-- =========================================================================
-- STEP 6 — Build proper DATETIME columns with cross-midnight handling
-- 
-- Problem: 828 rows had pickup_time appearing earlier than order_time when
-- compared as TIME values. Investigation showed all 828 fit the pattern
-- HOUR(order_time)=23 and HOUR(pickup_time)<=1 — orders placed late at
-- night with pickups happening just after midnight the next day.
-- 
-- Solution: combine date + time into DATETIME, and add 1 day to the
-- pickup date when pickup_time appears before order_time.
-- =========================================================================
ALTER TABLE deliveries 
ADD COLUMN order_datetime DATETIME,
ADD COLUMN pickup_datetime DATETIME;

-- Order datetime is always on the order date itself
UPDATE deliveries
SET order_datetime = TIMESTAMP(Order_Date, Order_Time)
WHERE Order_Date IS NOT NULL AND Order_Time IS NOT NULL;

-- Pickup datetime uses CASE WHEN to handle cross-midnight pickups
UPDATE deliveries
SET pickup_datetime = 
    CASE 
        WHEN Pickup_Time >= Order_Time 
            THEN TIMESTAMP(Order_Date, Pickup_Time)
        ELSE TIMESTAMP(DATE_ADD(Order_Date, INTERVAL 1 DAY), Pickup_Time)
    END
WHERE Order_Date IS NOT NULL AND Order_Time IS NOT NULL AND Pickup_Time IS NOT NULL;

-- Verify: no rows should have pickup before order after the fix
SELECT 
    SUM(CASE WHEN pickup_datetime < order_datetime THEN 1 ELSE 0 END) AS still_wrong,
    SUM(CASE WHEN pickup_datetime IS NULL AND Pickup_Time IS NOT NULL THEN 1 ELSE 0 END) AS unpopulated
FROM deliveries;
-- Expected: still_wrong=0, unpopulated=91 (the same 91 NaN-Order_Time rows)

-- =========================================================================
-- STEP 7 — Build the base cleaning view
-- Excludes the 91 incomplete records (defensive multi-column filter so the
-- view is robust against future data updates that might introduce different
-- NULL patterns).
-- =========================================================================
CREATE VIEW deliveries_clean AS
SELECT
    Order_ID,
    Agent_Age,
    Agent_Rating,
    Store_Latitude,
    Store_Longitude,
    Drop_Latitude,
    Drop_Longitude,
    Weather,
    Traffic,
    Vehicle,
    Area,
    Delivery_Time,
    Category,
    order_datetime,
    pickup_datetime
FROM deliveries
WHERE Weather IS NOT NULL
  AND Traffic IS NOT NULL
  AND order_datetime IS NOT NULL
  AND pickup_datetime IS NOT NULL;

-- Verify row count
SELECT COUNT(*) FROM deliveries_clean;
-- Expected: ~43,648 (43,739 total minus 91 incomplete records)
