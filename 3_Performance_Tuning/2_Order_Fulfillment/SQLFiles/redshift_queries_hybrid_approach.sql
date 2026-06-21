-- Disable result cache for accurate disk and compute benchmarking
SET enable_result_cache_for_session TO off;

-- =========================================================================
-- STEP 1: CREATE THE HYBRID VERSION
-- =========================================================================
-- This schema uses the balanced DISTKEY (fc_id) to avoid the 5.51 data skew,
-- while adding the SORTKEY on the release date to enable Zone Map Pruning.

DROP TABLE IF EXISTS aws_project.order_fulfillment_hybrid;

CREATE TABLE aws_project.order_fulfillment_hybrid
DISTSTYLE KEY
DISTKEY (fc_id)
SORTKEY (fc_release_to_mfg_date) AS
SELECT * FROM aws_project.order_fulfillment_stg;--Took:


SELECT COUNT(*) FROM aws_project.order_fulfillment_hybrid;
SELECT * FROM aws_project.order_fulfillment_hybrid LIMIT 10;


-- =========================================================================
-- STEP 2: THE 8 BUSINESS QUERIES
-- =========================================================================

-- Q1:
DROP TABLE IF EXISTS aws_project.temp_mfg_delivery_hybrid;
CREATE TABLE aws_project.temp_mfg_delivery_hybrid AS
SELECT
    mfg_facility_id,
    AVG(DATEDIFF(day, to_mfg_facility_arrival_date, from_mfg_facility_departure_date)) AS avg_delivery_days
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    mfg_facility_id
ORDER BY
    avg_delivery_days ASC;--Took (21st June): 37.3s, 5.8s, 6.2s, 5.6s, 6.5s
--Took (21st June): 7.7s, 12.1s, 6.1s, 11.2s, 6.6s (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 11.3s


-- Q2:
DROP TABLE IF EXISTS aws_project.temp_fc_backlog_hybrid;
CREATE TABLE aws_project.temp_fc_backlog_hybrid AS
SELECT
    fc_id,
    DATE(fc_release_to_mfg_date) AS backlog_date,
    SUM(fc_release_to_mfg_count - fc_arrival_from_mfg_count) AS daily_backlog
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    fc_id,
    DATE(fc_release_to_mfg_date)
ORDER BY
    daily_backlog DESC;--Took (21st June): 1m 26.6s, 1m 19.7s, 1m 14s, 1m 13.7s, 1m 13.4s
--Took (21st June): 1m 45.9s, 1m 50.4s, 1m 52.7s, 1m 50.3s, 1m 45.1s (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 1m 46.5s


-- Q3:
SELECT
    fc_id,
    COUNT(fc_inspection_date) AS total_inspections
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    fc_id
ORDER BY
    total_inspections DESC
LIMIT
    1;--Took (21st June): 12968 ms, 6547 ms, 4718 ms, 4358 ms, 4398 ms
--Took (21st June): 12179 ms, 48 ms, 65 ms, 48 ms, 48 ms
-- Final Run with multiple isolated sessions: 48 ms


-- Q4:
DROP TABLE IF EXISTS aws_project.temp_global_delay_hybrid;
CREATE TABLE aws_project.temp_global_delay_hybrid AS
SELECT
    AVG(DATEDIFF(day, fc_release_to_mfg_date, to_mfg_facility_arrival_date)) AS avg_system_delay_days
FROM aws_project.order_fulfillment_hybrid;--Took (21st June): 4.8s, 3.7s, 3.9s, 3.6s, 4s
--Took (21st June): 8.6s, 6.8s, 5.4s, 6.6s, 9.4s (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 5.4s


-- Q5:
SELECT
    fc_id,
    mfg_facility_id,
    SUM(fc_release_to_mfg_count) AS total_released
FROM aws_project.order_fulfillment_hybrid
WHERE
    fc_release_to_mfg_date >= DATE_TRUNC('year', GETDATE() - INTERVAL '1 year')
    AND fc_release_to_mfg_date < DATE_TRUNC('year', GETDATE())
GROUP BY
    fc_id, mfg_facility_id
ORDER BY
    total_released DESC
LIMIT
    1;--Took (21st June): 806 ms, 447 ms, 738 ms, 458 ms, 437 ms
--Took (21st June): 438 ms, 488 ms, 485 ms, 478 ms, 807 ms (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 578 ms


-- Q6:
DROP TABLE IF EXISTS aws_project.temp_backlog_audit_hybrid;
CREATE TABLE aws_project.temp_backlog_audit_hybrid AS
SELECT
    mfg_facility_id,
    SUM(mfg_facility_backlog_count) AS reported_backlog,
    SUM(mfg_facility_input_count - mfg_facility_output_count) AS actual_backlog
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    mfg_facility_id;--Took (21st June): 19.4s, 8.8s, 7.1s, 6.9s, 6.9s
--Took (21st June): 7.3s, 10.1s, 12.2s, 6.4s, 13.8s (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 11.9s


-- Q7:
SELECT
    mfg_facility_id,
    MAX(mfg_facility_product_capability_count) AS capability_score
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    mfg_facility_id
ORDER BY
    capability_score DESC
LIMIT
    25;--Took (21st June): 6318 ms, 2188 ms, 2098 ms, 2088 ms, 2168 ms
--Took (21st June): 3298 ms, 48 ms, 66 ms, 48 ms, 310 ms (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 304 ms


-- Q8:
DROP TABLE IF EXISTS aws_project.temp_capability_correlation_hybrid;
CREATE TABLE aws_project.temp_capability_correlation_hybrid AS
SELECT
    mfg_facility_product_capability_count AS capability_tier,
    AVG(mfg_facility_backlog_count) AS avg_reported_backlog
FROM aws_project.order_fulfillment_hybrid
GROUP BY
    mfg_facility_product_capability_count
ORDER BY
    capability_tier ASC;--Took (21st June): 3.8s, 3.6s, 3.9s, 3.8s, 3.8s
--Took (21st June): 2.6s, 2s, 2.7s, 2.4s, 2.6s (Real environment, multiple isolated sessions)
-- Final Run with multiple isolated sessions: 2.4s

