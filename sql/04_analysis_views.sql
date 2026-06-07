-- =========================================================================
-- 04_analysis_views.sql
-- Project: Amazon Delivery Performance & Logistics Analysis
-- Purpose: Build 10 analytical views that answer the project's core
--          business questions. These views are the data layer that the
--          Power BI dashboard imports from.
-- Run order: Execute LAST, after the feature view is built.
-- 
-- Headline findings exposed by these views:
--   - Agent rating CLIFF: Low-tier agents deliver on-time 15% vs ~56% for
--     other three tiers (Top/High/Medium are statistically identical).
--   - Traffic is the strongest condition: 72% on-time in Low traffic
--     collapses to 30% in Jam.
--   - Motorcycles underperform across ALL traffic conditions (~10 pp gap
--     vs scooters/vans), proving the weakness is intrinsic to the vehicle.
--   - 10 km is the operational breakpoint where on-time rates collapse.
--   - Evening (17:00-20:59) holds 41% of orders but only 36% on-time.
--   - Cloudy weather underperforms Stormy/Sandstorms (counterintuitive).
--   - Weekend vs weekday shows no meaningful difference.
-- 
-- Design notes on sort-helper columns:
--   - Several views include a `*_order` column purely for Power BI sort.
--     Power BI's "Sort by column" feature uses these to display categorical
--     values in business-meaningful order (e.g., Low -> Medium -> High ->
--     Jam, instead of alphabetical High -> Jam -> Low -> Medium).
-- =========================================================================

USE amazon_delivery;

-- =========================================================================
-- 1. Overall KPIs
-- Single-row view for top-line dashboard KPI cards.
-- =========================================================================
CREATE VIEW analysis_overall_kpis AS
SELECT
    COUNT(Order_ID) AS total_orders,
    ROUND(SUM(is_on_time) / COUNT(Order_ID) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(delivery_speed_kmh), 2) AS avg_speed_kmh,
    ROUND(AVG(pickup_delay_min), 2) AS avg_pickup_delay_min
FROM deliveries_features;

-- =========================================================================
-- 2. On-time rate by traffic condition
-- Strongest single predictor: 72% (Low) drops to 30% (Jam).
-- =========================================================================
CREATE VIEW analysis_ontime_by_traffic AS
SELECT
    Traffic,
    COUNT(*) AS total_orders,
    SUM(is_on_time) AS on_time_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes
FROM deliveries_features
GROUP BY Traffic
ORDER BY on_time_pct DESC;

-- =========================================================================
-- 3. On-time rate by weather
-- Counterintuitive finding: Cloudy (39%) worse than Stormy (47%) and
-- Sandstorms (47%), possibly reflecting pre-rain road conditions.
-- =========================================================================
CREATE VIEW analysis_ontime_by_weather AS
SELECT
    Weather,
    COUNT(*) AS total_orders,
    SUM(is_on_time) AS on_time_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes
FROM deliveries_features
GROUP BY Weather
ORDER BY on_time_pct DESC;

-- =========================================================================
-- 4. On-time rate by vehicle type
-- Scooter and Van both ~54% on-time; Motorcycle 45%. Motorcycles handle
-- 59% of all volume despite being slowest — investigated further in view 6.
-- =========================================================================
CREATE VIEW analysis_ontime_by_vehicle AS
SELECT
    Vehicle,
    COUNT(*) AS total_orders,
    SUM(is_on_time) AS on_time_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes
FROM deliveries_features
GROUP BY Vehicle
ORDER BY on_time_pct DESC;

-- =========================================================================
-- 5. On-time rate by area
-- Semi-Urban shows 5% on-time, but with only 138 deliveries — small sample
-- warrants caution in interpretation.
-- =========================================================================
CREATE VIEW analysis_ontime_by_area AS
SELECT
    Area,
    COUNT(*) AS total_orders,
    SUM(is_on_time) AS on_time_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes
FROM deliveries_features
GROUP BY Area
ORDER BY on_time_pct DESC;

-- =========================================================================
-- 6. Multi-dimensional: speed and on-time by vehicle x traffic
-- 
-- THE matrix that proves motorcycles underperform across ALL traffic
-- conditions, not just because they handle more volume. The heatmap of
-- this view is the Page 2 centerpiece of the Power BI dashboard.
-- 
-- traffic_order is used by Power BI's "Sort by column" feature to display
-- traffic levels in operational order (Low to Jam) rather than alphabetical.
-- =========================================================================
CREATE VIEW analysis_speed_by_vehicle_traffic AS
SELECT
    CASE Traffic
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Jam' THEN 4
    END AS traffic_order,
    Vehicle,
    Traffic,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_speed_kmh), 2) AS avg_speed_kmh,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct
FROM deliveries_features
GROUP BY Vehicle, Traffic
ORDER BY Vehicle, traffic_order;

-- =========================================================================
-- 7. Performance by agent rating tier — THE HEADLINE INSIGHT
-- 
-- Reveals a sharp threshold effect: Top, High, and Medium tiers all
-- perform similarly (~56% on-time), but Low-tier agents collapse to 15%.
-- This is the strongest single insight in the project and the centerpiece
-- visual on Page 3 of the dashboard.
-- 
-- tier_order is for Power BI sort (Top -> Low order).
-- =========================================================================
CREATE VIEW analysis_performance_by_rating_tier AS
SELECT 
    CASE agent_rating_tier
        WHEN 'Top' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
    END AS tier_order,
    agent_rating_tier,
    COUNT(*) AS total_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes,
    ROUND(AVG(delivery_speed_kmh), 2) AS avg_speed_kmh
FROM deliveries_features
WHERE agent_rating_tier IS NOT NULL
GROUP BY agent_rating_tier
ORDER BY tier_order;

-- =========================================================================
-- 8. Time of day x weekend pattern
-- 
-- Evening is the worst time (36% on-time) despite holding 41% of total
-- volume — a major capacity-vs-demand mismatch.
-- 
-- Weekend (is_weekend=1) shows essentially identical numbers to weekday
-- (~1 pp difference) — documenting a "non-finding" is itself a finding.
-- 
-- time_order is for Power BI sort. day_type (Weekday/Weekend) is a
-- human-readable label for is_weekend used in dashboard matrix.
-- =========================================================================
CREATE VIEW analysis_time_of_day_pattern AS
SELECT
    CASE time_of_day
        WHEN 'Morning' THEN 1
        WHEN 'Afternoon' THEN 2
        WHEN 'Evening' THEN 3
        WHEN 'Night' THEN 4
    END AS time_order,
    time_of_day,
    is_weekend,
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes
FROM deliveries_features
GROUP BY time_of_day, is_weekend
ORDER BY time_order;

-- =========================================================================
-- 9. Distance vs delivery time
-- 
-- Reveals a clear operational breakpoint at 10 km: on-time rates fall
-- from 52-65% under 10 km to 37% beyond. Effective speed simultaneously
-- increases with distance (longer trips spend less time on per-delivery
-- overhead).
-- 
-- Note: GROUP BY repeats the full CASE expressions to satisfy MySQL's
-- only_full_group_by mode (a SELECT column that references the base
-- column distance_km must be deterministic from the GROUP BY clause).
-- =========================================================================
CREATE VIEW analysis_distance_vs_time AS
SELECT 
    CASE 
        WHEN distance_km <= 5 THEN 1
        WHEN distance_km <= 10 THEN 2
        WHEN distance_km <= 15 THEN 3
        ELSE 4
    END AS distance_order,
    CASE 
        WHEN distance_km <= 5 THEN '0-5 km'
        WHEN distance_km <= 10 THEN '5-10 km'
        WHEN distance_km <= 15 THEN '10-15 km'
        ELSE '15+ km'
    END AS distance_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(Delivery_Time), 2) AS avg_delivery_minutes,
    ROUND(AVG(delivery_speed_kmh), 2) AS avg_speed_kmh,
    ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct
FROM deliveries_features
GROUP BY 
    CASE 
        WHEN distance_km <= 5 THEN 1
        WHEN distance_km <= 10 THEN 2
        WHEN distance_km <= 15 THEN 3
        ELSE 4
    END,
    CASE 
        WHEN distance_km <= 5 THEN '0-5 km'
        WHEN distance_km <= 10 THEN '5-10 km'
        WHEN distance_km <= 15 THEN '10-15 km'
        ELSE '15+ km'
    END
ORDER BY distance_order;

-- =========================================================================
-- 10. Vehicle rank within traffic condition (window function)
-- 
-- Uses RANK() OVER PARTITION BY to rank vehicles within each traffic
-- level. Confirms motorcycles rank LAST in every traffic condition —
-- vans only beat scooters in Jam traffic (otherwise scooters lead).
-- =========================================================================
CREATE VIEW analysis_vehicle_rank_by_traffic AS
SELECT 
    Traffic,
    Vehicle,
    total_orders,
    on_time_pct,
    RANK() OVER (PARTITION BY Traffic ORDER BY on_time_pct DESC) AS vehicle_rank_in_traffic
FROM (
    SELECT 
        Traffic,
        Vehicle,
        COUNT(*) AS total_orders,
        ROUND(AVG(is_on_time) * 100, 2) AS on_time_pct
    FROM deliveries_features
    GROUP BY Traffic, Vehicle
) t
ORDER BY Traffic, vehicle_rank_in_traffic;
