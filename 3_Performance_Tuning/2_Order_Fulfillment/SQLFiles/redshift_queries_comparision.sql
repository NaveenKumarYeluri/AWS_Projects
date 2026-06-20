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
--Next Day (18th June): 10.4s, 7.5s, 6s, 6s, 6.3s
--Next (19th June): 1m 11.5s, 6.6s, 7.6s, 8.3s, 6.4s
--Next (19th June): 5.9s, 4.8s, 4.4s, 4.5s, 4.4s
--Next (20th June): 56.3s, 5.9s, 6.1s, 5.9s, 6s (exception, 5 continous runs)


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
--Next Day (18th June): 8.4s, 6.7s, 5.3s, 5.4s, 5.4s
--Next (19th June): 34.1s, 6.6s, 6.6s, 7.4s, 6s
--Next (19th June): 5.3s, 5.2s, 5.3s, 5.4s, 5.3s
--Next (20th June): 24.4s, 5.8s, 5.9s, 5.7s, 5.5s (exception, 5 continous runs)



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
--Next Day (18th June): 1m 21.7s, 1m 11.9s, 59.2s, 57.7s, 58s
--Next (19th June): 1m 44.3s, 1m 11.9s, 1m 11.6s, 1m 12s, 58.2s
--Next (19th June): 59.8s, 56.8s, 56.3s, 56.7s, 56.5s
--Next (20th June): 1m 17.5s, 59.5s, 1m 0.2s, 57.8s, 57.3s (exception, 5 continous runs)


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
--Next Day (18th June): 1m 34.7s, 1m 22.1s, 1m 6.1s, 1m 7s, 1m 6.7s
--Next (19th June): 1m 32.8s, 1m 28.3s, 1m 23.9s, 1m 8s, 1m 6.2s
--Next (20th June): 1m 22s, 1m 10s, 1m 2s, 55s, 55.6s (exception, 5 continous runs)



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
--Next Day (18th June): 4847 ms, 49 ms, 49 ms, 63 ms, 69 ms
--Next (19th June): 4659 ms, 48 ms, 55 ms, 49 ms, 49 ms
--Next (19th June): 3748 ms, 3738 ms, 3758 ms, 3788 ms, 3748 ms
--Next (20th June): 3694 ms, 3325 ms, 4342 ms, 3334 ms, 3329 ms (exception, 5 continous runs)


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
--Next Day (18th June): 7099 ms, 60 ms, 48 ms, 48 ms, 49 ms
--Next (19th June): 5029 ms, 58 ms, 49 ms,  48 ms, 58 ms
--Next (19th June): 4419 ms, 4498 ms, 4429 ms, 4389 ms, 4448 ms
--Next (20th June): 4506 ms, 3757 ms, 3756 ms, 3780 ms, 3783 ms (exception, 5 continous runs)


-- Q4:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_global_delay_def;
CREATE TABLE aws_project.temp_global_delay_def AS
SELECT
    AVG(DATEDIFF(day, fc_release_to_mfg_date, to_mfg_facility_arrival_date)) AS avg_system_delay_days
FROM aws_project.order_fulfillment_def;--Took (15th June): 13.3s, 4.1s, 4.3s, 4.3s, 4.3s
--Next Day (18th June): 5.1s, 3.7s, 3.7s, 4s, 3.6s
--Next (19th June): 4.7s, 4.1s, 4.2s, 4s, 4s
--Next (19th June): 4.1s, 4.1s, 4.1s, 4.1s, 4.2s
--Next (20th June): 4.2s, 757ms, 752ms, 744ms, 787ms (exception, 5 continous runs)


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_global_delay_opt;
CREATE TABLE aws_project.temp_global_delay_opt AS
SELECT
    AVG(DATEDIFF(day, fc_release_to_mfg_date, to_mfg_facility_arrival_date)) AS avg_system_delay_days
FROM aws_project.order_fulfillment_opt;--Took (15th June): 7.5s, 4.7s, 4.5s, 4.6s, 4.6s
--Next Day (18th June): 5.1s, 4.6s, 4.5s, 4.6s, 4.5s
--Next (19th June): 5s, 4.8s, 5.2s, 4.5s, 4.5s
--Next (19th June): 4.6s, 4.6s, 4.6s, 4.6s, 4.6s
--Next (20th June): 4.2s, 709ms, 693ms, 711ms, 752ms (exception, 5 continous runs)



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
--Next Day (18th June): 3978 ms, 3668 ms, 3620 ms, 3579 ms, 3639 ms
--Next (19th June): 3879 ms, 3679 ms, 5018 ms, 3599 ms, 3548 ms
--Next (19th June): 3449 ms, 3137 ms, 3138 ms, 3151 ms, 3208 ms
--Next (20th June): 2721 ms, 2544 ms, 2525 ms, 2525 ms, 2421 ms (exception, 5 continous runs)


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
--Next Day (18th June): 1039 ms, 527 ms, 459 ms, 537 ms, 469 ms
--Next (19th June): 1038 ms, 839 ms, 1048 ms, 459 ms, 509 ms
--Next (19th June): 479 ms, 569 ms, 499 ms, 529 ms, 418 ms
--Next (20th June): 398 ms, 239 ms, 236 ms, 242 ms, 234 ms (exception, 5 continous runs)



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
--Next Day (18th June): 6.9s, 4.6s, 4.5s, 4.4s, 4.3s
--Next (19th June): 6.9s, 6.7s, 8.4s, 4.5s, 4.6s
--Next (19th June): 4.5s, 4.6s, 4.3s, 4.5s, 4.5s
--Next (20th June): 4.4s, 4.4s, 3.7s, 3.8s, 3.7s (exception, 5 continous runs)


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
--Next Day (18th June): 6.7s, 4.8s, 4.8s, 4.7s, 4.8s
--Next (19th June): 6.4s, 6.4s, 7.6s, 4.8s, 4.7s
--Next (19th June): 4.9s, 4.8s, 5s, 4.9s, 4.8s
--Next (20th June): 4.9s, 3.6s, 3.6s, 3.6s, 3.5s (exception, 5 continous runs)



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
--Next Day (18th June): 2739 ms, 68 ms, 47 ms, 49 ms, 58 ms
--Next (19th June): 2566 ms, 58 ms, 47 ms, 58 ms, 48 ms
--Next (19th June): 2097 ms, 2085 ms, 2087 ms, 2088 ms, 2089 ms
--Next (20th June): 2152 ms, 1958 ms, 1955 ms, 1958 ms, 1961 ms (exception, 5 continous runs)


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
--Next Day (18th June): 2416 ms, 57 ms, 59 ms, 49 ms, 55 ms
--Next (19th June): 2347 ms, 68 ms, 49 ms, 50 ms, 49 ms
--Next (19th June): 1843 ms, 1879 ms, 1837 ms, 1879 ms, 1832 ms
--Next (20th June): 1923 ms, 1752 ms, 1749 ms, 1754 ms, 1754 ms (exception, 5 continous runs)



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
--Next Day (18th June): 4.3s, 1.8s, 1.8s, 1.7s, 1.8s
--Next (19th June): 4.2s, 4.2s, 4.5s, 1.8s, 1.8s
--Next (20th June): 2.1s, 1.7s, 1.7s, 1.8s, 1.7s (exception, 5 continous runs)


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
--Next Day (18th June): 4.1s, 2.3s, 2.3s, 2.4s, 2.4s
--Next (19th June): 4s, 4.2s, 4.5s, 2.3s, 2.3s
--Next (19th June): 2.3s, 2.3s, 2.1s, 2.3s, 2.3s
--Next (20th June): 2.1s, 1.7s, 1.7s, 1.8s, 1.7s (exception, 5 continous runs)
