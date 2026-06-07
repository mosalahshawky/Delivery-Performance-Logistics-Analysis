-- =========================================================================
-- 03_features_and_geo.sql
-- Project: Amazon Delivery Performance & Logistics Analysis
-- Purpose: Build the geo-cleaned view (with Haversine distance calculation
--          and outlier filtering) and the comprehensive feature view that
--          adds 10 engineered features for analytical work.
-- Run order: Execute THIRD, after 02_data_cleaning.sql.
-- 
-- View architecture (medallion pattern):
--   deliveries (raw)
--     └─ deliveries_clean       (drops 91 incomplete records)
--          └─ deliveries_geo_clean  (drops Null Island + distance outliers,
--                                    adds Haversine distance_km)
--               └─ deliveries_features  (all engineered features — the
--                                        dashboard data source)
-- 
-- Key data quality finding addressed here:
--   - The Haversine calculation revealed 156 rows with distances exceeding
--     500 km — clearly coordinate errors for last-mile delivery. Distance
--     distribution split cleanly: ~40,000 rows under 30 km (avg 9.7 km) and
--     exactly 156 rows beyond 500 km. Excluded via 50 km threshold filter.
-- =========================================================================

USE amazon_delivery;

-- =========================================================================
-- VIEW: deliveries_geo_clean
-- 
-- Adds the Haversine great-circle distance calculation between store and
-- drop coordinates. Filters two classes of geo data quality issues:
--   1. Null Island rows where either coordinate pair is at (0,0)
--   2. Distance outliers exceeding 50 km (coordinate errors)
-- 
-- The Haversine formula assumes Earth radius = 6371 km. All angle inputs
-- must be converted from degrees to radians.
-- =========================================================================
CREATE VIEW deliveries_geo_clean AS
SELECT *
FROM (
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
        pickup_datetime,
        -- Haversine formula: great-circle distance in km
        ROUND(
            6371 * 2 * ASIN(SQRT(
                POWER(SIN(RADIANS(Drop_Latitude - Store_Latitude) / 2), 2) +
                COS(RADIANS(Store_Latitude)) * COS(RADIANS(Drop_Latitude)) *
                POWER(SIN(RADIANS(Drop_Longitude - Store_Longitude) / 2), 2)
            )), 2
        ) AS distance_km
    FROM deliveries_clean
    -- Exclude Null Island rows (placeholder coordinates at 0,0)
    WHERE NOT (Drop_Latitude BETWEEN -0.1 AND 0.1 AND Drop_Longitude BETWEEN -0.1 AND 0.1)
      AND NOT (Store_Latitude BETWEEN -0.1 AND 0.1 AND Store_Longitude BETWEEN -0.1 AND 0.1)
) t
WHERE distance_km <= 50;
-- Expected: ~39,997 rows (43,648 - 3,505 Null Island - 156 distance outliers)

-- Verify the geo view
SELECT 
    COUNT(*) AS total_rows,
    ROUND(MIN(distance_km), 2) AS min_dist,
    ROUND(MAX(distance_km), 2) AS max_dist,
    ROUND(AVG(distance_km), 2) AS avg_dist
FROM deliveries_geo_clean;
-- Expected: ~40k rows, min ~1.5, max <=50, avg ~9.7

-- =========================================================================
-- VIEW: deliveries_features
-- 
-- The comprehensive analytical layer. Adds 10 engineered features on top
-- of the geo-clean data:
--   1.  is_on_time           — boolean flag, 1 if delivery_time <= 120 min
--   2.  delivery_speed_bucket — Fast / Normal / Slow / Very Slow
--   3.  pickup_delay_min     — minutes between order and pickup
--   4.  time_of_day          — Morning / Afternoon / Evening / Night
--   5.  day_of_week          — Monday, Tuesday, etc.
--   6.  is_weekend           — boolean flag (Sat/Sun = 1)
--   7.  agent_age_group      — 18-24 / 25-34 / 35-44
--   8.  agent_rating_tier    — Top / High / Medium / Low
--   9.  distance_km          — inherited from deliveries_geo_clean (Haversine)
--   10. delivery_speed_kmh   — derived: distance_km / (delivery_time / 60)
-- 
-- Threshold calibration notes:
--   - 120-min on-time threshold chosen after distribution analysis.
--     Initial 30-min industry-standard threshold classified 96% of orders
--     as late — clearly miscalibrated for this dataset (which appears to
--     be B2C parcel delivery, not quick-commerce). 120 minutes produces
--     a balanced ~49/51 on-time vs late split.
--   - Agent rating tier thresholds (4.8 / 4.6 / 4.5) chosen to roughly
--     equalize tier sizes based on observed rating distribution.
-- =========================================================================
CREATE VIEW deliveries_features AS
SELECT 
    Order_ID,
    Agent_Age,
    Agent_Rating,
    Weather,
    Traffic,
    Vehicle,
    Area,
    Delivery_Time,
    Category,
    order_datetime,
    pickup_datetime,
    distance_km,
    -- Derived speed: km per hour
    ROUND(distance_km / (Delivery_Time / 60.0), 2) AS delivery_speed_kmh,
    -- Binary on-time flag
    CASE WHEN Delivery_Time <= 120 THEN 1 ELSE 0 END AS is_on_time,
    -- Categorical speed bucket
    CASE 
        WHEN Delivery_Time <= 60 THEN 'Fast'
        WHEN Delivery_Time <= 120 THEN 'Normal'
        WHEN Delivery_Time <= 180 THEN 'Slow'
        ELSE 'Very Slow'
    END AS delivery_speed_bucket,
    -- Time between order and pickup, in minutes
    TIMESTAMPDIFF(MINUTE, order_datetime, pickup_datetime) AS pickup_delay_min,
    -- Time-of-day bucket
    CASE 
        WHEN HOUR(order_datetime) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN HOUR(order_datetime) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(order_datetime) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    -- Day of week name and weekend flag
    DAYNAME(order_datetime) AS day_of_week,
    CASE WHEN DAYOFWEEK(order_datetime) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    -- Agent age bucket (no agents 45+ in dataset)
    CASE 
        WHEN Agent_Age < 25 THEN '18-24'
        WHEN Agent_Age < 35 THEN '25-34'
        ELSE '35-44'
    END AS agent_age_group,
    -- Agent rating tier — note NULL handling (54 NULL ratings preserved)
    CASE 
        WHEN Agent_Rating >= 4.8 THEN 'Top'
        WHEN Agent_Rating >= 4.6 THEN 'High'
        WHEN Agent_Rating >= 4.5 THEN 'Medium'
        WHEN Agent_Rating IS NOT NULL THEN 'Low'
        ELSE NULL
    END AS agent_rating_tier
FROM deliveries_geo_clean;

-- Verify the feature view
SELECT COUNT(*) FROM deliveries_features;
-- Expected: ~39,997 rows (same as deliveries_geo_clean)
