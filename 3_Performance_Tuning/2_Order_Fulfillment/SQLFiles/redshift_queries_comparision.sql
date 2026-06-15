-- We will be creating a temp table for queries which output fecth load of records,
-- so the query time cannot be obstructed by network or client rendering.
-- We will be disabling result cache as well.

SET enable_result_cache_for_session TO off;



-- Q1:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_mfg_delivery_def;
CREATE TABLE aws_project.temp_mfg_delivery_def AS
SELECT
    mfg_facility_id,
    AVG(DATEDIFF(day, to_mfg_facility_arrival_date, from_mfg_facility_departure_date)) AS avg_delivery_days
FROM aws_project.order_fulfillment_def
GROUP BY
    mfg_facility_id
ORDER BY
    avg_delivery_days ASC;--Took (15th June): 2m 21.3s, 19.1s, 4.7s, 4.8s, 4.7s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_mfg_delivery_opt;
CREATE TABLE aws_project.temp_mfg_delivery_opt AS
SELECT
    mfg_facility_id,
    AVG(DATEDIFF(day, to_mfg_facility_arrival_date, from_mfg_facility_departure_date)) AS avg_delivery_days
FROM aws_project.order_fulfillment_opt
GROUP BY
    mfg_facility_id
ORDER BY
    avg_delivery_days ASC;--Took (15th June): 49.9s, 11.9s, 3.9s, 3.4s, 3.5s



-- Q2:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_fc_backlog_def;
CREATE TABLE aws_project.temp_fc_backlog_def AS
SELECT
    fc_id,
    DATE(fc_release_to_mfg_date) AS backlog_date,
    SUM(fc_release_to_mfg_count - fc_arrival_from_mfg_count) AS daily_backlog
FROM aws_project.order_fulfillment_def
GROUP BY
    fc_id,
    DATE(fc_release_to_mfg_date)
ORDER BY
    daily_backlog DESC;--Took (15th June): 1m 47s, 1m 19.3s, 59s, 58.2s, 58.1s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_fc_backlog_opt;
CREATE TABLE aws_project.temp_fc_backlog_opt AS
SELECT
    fc_id,
    DATE(fc_release_to_mfg_date) AS backlog_date,
    SUM(fc_release_to_mfg_count - fc_arrival_from_mfg_count) AS daily_backlog
FROM aws_project.order_fulfillment_opt
GROUP BY
    fc_id,
    DATE(fc_release_to_mfg_date)
ORDER BY
    daily_backlog DESC;--Took (15th June): 2m 2.1s, 1m 25.9s, 1m 6.4s, 1m 6.7s, 1m 6.5s



-- Q3:
-- --- DEFAULT VERSION ---
SELECT
    fc_id,
    COUNT(fc_inspection_date) AS total_inspections
FROM aws_project.order_fulfillment_def
GROUP BY
    fc_id
ORDER BY
    total_inspections DESC
LIMIT
    1;--Took (15th June): 15260 ms, 168003 ms, 3706 ms, 3696 ms, 3687 ms


-- --- OPTIMIZED VERSION ---
SELECT
    fc_id,
    COUNT(fc_inspection_date) AS total_inspections
FROM aws_project.order_fulfillment_opt
GROUP BY
    fc_id
ORDER BY
    total_inspections DESC
LIMIT
    1;--Took (15th June): 15451 ms, 59332 ms, 10195 ms, 10119 ms, 10081 ms



-- Q4:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_global_delay_def;
CREATE TABLE aws_project.temp_global_delay_def AS
SELECT
    AVG(DATEDIFF(day, fc_release_to_mfg_date, to_mfg_facility_arrival_date)) AS avg_system_delay_days
FROM aws_project.order_fulfillment_def;--Took (15th June): 13.3s, 4.1s, 4.3s, 4.3s, 4.3s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_global_delay_opt;
CREATE TABLE aws_project.temp_global_delay_opt AS
SELECT
    AVG(DATEDIFF(day, fc_release_to_mfg_date, to_mfg_facility_arrival_date)) AS avg_system_delay_days
FROM aws_project.order_fulfillment_opt;--Took (15th June): 7.5s, 4.7s, 4.5s, 4.6s, 4.6s



-- Q5:
-- --- DEFAULT VERSION ---
SELECT
    fc_id,
    mfg_facility_id,
    SUM(fc_release_to_mfg_count) AS total_released
FROM aws_project.order_fulfillment_def
WHERE
    fc_release_to_mfg_date >= DATE_TRUNC('year', GETDATE() - INTERVAL '1 year')
    AND fc_release_to_mfg_date < DATE_TRUNC('year', GETDATE())
GROUP BY
    fc_id, mfg_facility_id
ORDER BY
    total_released DESC
LIMIT
    1;--Took (15th June): 3060 ms, 2761 ms, 2564 ms, 2648 ms, 2569 ms


-- --- OPTIMIZED VERSION ---
SELECT
    fc_id,
    mfg_facility_id,
    SUM(fc_release_to_mfg_count) AS total_released
FROM aws_project.order_fulfillment_opt
WHERE
    fc_release_to_mfg_date >= DATE_TRUNC('year', GETDATE() - INTERVAL '1 year')
    AND fc_release_to_mfg_date < DATE_TRUNC('year', GETDATE())
GROUP BY
    fc_id, mfg_facility_id
ORDER BY
    total_released DESC
LIMIT
    1;--Took (15th June): 616 ms, 451 ms, 313 ms, 320 ms, 312 ms



-- Q6:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_backlog_audit_def;
CREATE TABLE aws_project.temp_backlog_audit_def AS
SELECT
    mfg_facility_id,
    SUM(mfg_facility_backlog_count) AS reported_backlog,
    SUM(mfg_facility_input_count - mfg_facility_output_count) AS actual_backlog
FROM aws_project.order_fulfillment_def
GROUP BY
    mfg_facility_id;--Took (15th June): 11.5s, 4.2s, 3.9s, 4.2s, 3.9s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_backlog_audit_opt;
CREATE TABLE aws_project.temp_backlog_audit_opt AS
SELECT
    mfg_facility_id,
    SUM(mfg_facility_backlog_count) AS reported_backlog,
    SUM(mfg_facility_input_count - mfg_facility_output_count) AS actual_backlog
FROM aws_project.order_fulfillment_opt
GROUP BY
    mfg_facility_id;--Took (15th June): 11.3s, 4.2s, 3.7s, 3.5s, 3.7s



-- Q7:
-- --- DEFAULT VERSION ---
SELECT
    mfg_facility_id,
    MAX(mfg_facility_product_capability_count) AS capability_score
FROM aws_project.order_fulfillment_def
GROUP BY
    mfg_facility_id
ORDER BY
    capability_score DESC
LIMIT
    25;--Took (15th June): 4726 ms, 2062 ms, 1953 ms, 1964 ms, 1966 ms


-- --- OPTIMIZED VERSION ---
SELECT
    mfg_facility_id,
    MAX(mfg_facility_product_capability_count) AS capability_score
FROM aws_project.order_fulfillment_opt
GROUP BY
    mfg_facility_id
ORDER BY
    capability_score DESC
LIMIT
    25;--Took (15th June): 4993 ms, 1845 ms, 1751 ms, 1749 ms, 1747 ms



-- Q8:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_capability_correlation_def;
CREATE TABLE aws_project.temp_capability_correlation_def AS
SELECT
    mfg_facility_product_capability_count AS capability_tier,
    AVG(mfg_facility_backlog_count) AS avg_reported_backlog
FROM aws_project.order_fulfillment_def
GROUP BY
    mfg_facility_product_capability_count
ORDER BY
    capability_tier ASC;--Took (15th June): 2.6s, 1.9s, 1.8s, 1.7s, 1.8s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_capability_correlation_opt;
CREATE TABLE aws_project.temp_capability_correlation_opt AS
SELECT
    mfg_facility_product_capability_count AS capability_tier,
    AVG(mfg_facility_backlog_count) AS avg_reported_backlog
FROM aws_project.order_fulfillment_opt
GROUP BY
    mfg_facility_product_capability_count
ORDER BY
    capability_tier ASC;--Took (15th June): 2.6s, 1.9s, 1.7s, 1.8s, 2.1s
