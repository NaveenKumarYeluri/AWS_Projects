-- We will be creating a temp table for queries which are going to fecth load of records,
-- so the query time cannot be obstructed by network or client rendering.
-- We will be disabling result cache as well.

SET enable_result_cache_for_session TO off;



-- Q1:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_customer_order_history_def;
CREATE TABLE aws_project.temp_customer_order_history_def AS
SELECT
    customer_id,
    order_id,
    order_date,
    final_order_amount
FROM aws_project.order_transaction_def
WHERE
    order_date >= GETDATE() - INTERVAL '8 years'
    AND order_date <= GETDATE() - INTERVAL '2 years'
ORDER BY
    customer_id,
    order_date;-- Took: 2m 33.4s, 2m 18.4s, 1m 9.1s, 1m 11.3s, 1m 10.3s
-- Next Day (2nd June) Runs: 2m 19s, 1m 19.9s, 1m 19.7s, 1m 17.9s, 1m 20s
-- Next Day (3rd June): 1m 5s, 1m 5s, 1m 5.2s
-- Next Day (6th June): 1m 55s, 1m 8.6s, 1m 5.1s
-- Next (7th June): 2m 14.6s, 1m 15.1s, 1m 7.9s, 1m 8.2s, 1m 8.3s
-- Next (9th June): 1m 12.8s, 1m 12.8s, 1m 10.9s, 1m 5.7s, 1m 4.9s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_customer_order_history_opt;
CREATE TABLE aws_project.temp_customer_order_history_opt AS
SELECT
    customer_id,
    order_id,
    order_date,
    final_order_amount
FROM aws_project.order_transaction_opt
WHERE
    order_date >= GETDATE() - INTERVAL '8 years'
    AND order_date <= GETDATE() - INTERVAL '2 years'
ORDER BY
    customer_id,
    order_date;-- Took: 1m 45.8s, 1m 6.8s, 1m 10.1s, 1m 8.3s, 1m 7.9s
-- Next Day (2nd June) Runs: 1m 31.9s, 1m 18.2s, 1m 17.4s, 1m 17.5s, 1m 8.4s
-- Next Day (3rd June): 1m 10.4s, 1m 12.8s, 1m 11.1s
-- Next Day (6th June): 1m 41.9s, 1m 11.3s, 1m 11s
-- Next (7th June): 1m 23.3s, 1m 19.9s, 1m 20.6s, 1m 10.1s, 1m 7.2s
-- Next (9th June): 1m 8.8s, 1m 2.9s, 59.7s, 59.8s, 1m 1s


-- Q2:
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_discount_credit_def;
CREATE TABLE aws_project.temp_discount_credit_def AS
SELECT
    customer_credit_rating,
    MIN(order_discount_pct) AS min_discount_pct,
    MAX(order_discount_pct) AS max_discount_pct,
    AVG(order_discount_pct) AS avg_discount_pct
FROM aws_project.order_transaction_def
GROUP BY
    customer_credit_rating
ORDER BY
    customer_credit_rating DESC;-- Took: 17s, 4.8s, 5s, 4.6s, 4.9s
-- Next Day (2nd June) Runs: 10.9s, 7.8s, 7.4s, 7.4s, 4.5s
-- Next Day (3rd June): 4.1s, 4.4s, 4.6s
-- Next Day (6th June): 9.3s, 4s, 4.7s
-- Next (7th June): 8.7s, 6.6s, 6.8s, 6.7s, 7s
-- Next (9th June): 4.4s, 4.2s, 4.2s, 4s, 4.2s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_discount_credit_opt;
CREATE TABLE aws_project.temp_discount_credit_opt AS
SELECT
    customer_credit_rating,
    MIN(order_discount_pct) AS min_discount_pct,
    MAX(order_discount_pct) AS max_discount_pct,
    AVG(order_discount_pct) AS avg_discount_pct
FROM aws_project.order_transaction_opt
GROUP BY
    customer_credit_rating
ORDER BY
    customer_credit_rating DESC;-- Took: 22.4s, 4.7s, 5.1s, 5s, 5.3s
-- Next Day (2nd June) Runs: 13.1s, 7.7s, 7.5s, 7.5s, 4.7s
-- Next Day (3rd June): 4.8s, 4.2s, 4.5s
-- Next Day (6th June): 8.4s, 4.3s, 5s
-- Next (7th June): 7.6s, 7.5s, 7.2s, 7s, 7.2s
-- Next (9th June): 5s, 4.4s, 4.5s, 4.3s, 4.1s



-- Q3:
-- --- DEFAULT VERSION ---
SELECT
    customer_country,
    COUNT(order_id) AS total_orders
FROM aws_project.order_transaction_def
WHERE
    order_date >= '2025-01-01 00:00:00'
    AND order_date <= '2025-12-31 23:59:59'
GROUP BY
    customer_country
ORDER BY
    total_orders DESC
LIMIT
    1;-- Took: 21596 ms, 8330 ms, 6408 ms, 6824 ms, 6993 ms
-- Next Day (2nd June) Runs: 12783 ms, 10656 ms, 8183 ms, 8181 ms, 8177 ms
-- Next Day (3rd June): 5539 ms, 5373 ms, 5370 ms
-- Next Day (6th June): 8415 ms, 15 ms, 8 ms
-- Next (7th June): 8189 ms, 8 ms, 10 ms, 9 ms, 8 ms
-- Next (9th June): 2087 ms, 7 ms, 6 ms, 8 ms, 6 ms

SELECT
    customer_country,
    COUNT(order_id) AS total_orders
FROM aws_project.order_transaction_def
WHERE
    order_date >= DATE_TRUNC('year', GETDATE() - INTERVAL '1 year')
    AND order_date < DATE_TRUNC('year', GETDATE())
GROUP BY
    customer_country
ORDER BY
    total_orders DESC
LIMIT
    1;-- Took (9th June): 4511 ms, 4331 ms, 4297 ms, 4346 ms, 4340 ms
-- Next (9th June): 10766 ms, 8826 ms, 7953 ms, 7987 ms, 6209 ms


-- --- OPTIMIZED VERSION ---
SELECT
    customer_country,
    COUNT(order_id) AS total_orders
FROM aws_project.order_transaction_opt
WHERE
    order_date >= '2025-01-01 00:00:00'
    AND order_date <= '2025-12-31 23:59:59'
GROUP BY
    customer_country
ORDER BY
    total_orders DESC
LIMIT
    1;-- Took: 13975 ms, 434 ms, 254 ms, 270 ms, 288 ms
-- Next Day (2nd June) Runs: 1289 ms, 939 ms, 968 ms, 975 ms, 271 ms
-- Next Day (3rd June): 396 ms, 193 ms, 190 ms
-- Next Day (6th June): 1286 ms, 9 ms, 9 ms
-- Next (7th June): 423 ms, 9 ms, 11 ms, 7 ms, 8 ms
-- Next (9th June): 251 ms, 6 ms, 6 ms, 10 ms, 7 ms

SELECT
    customer_country,
    COUNT(order_id) AS total_orders
FROM aws_project.order_transaction_opt
WHERE
    order_date >= DATE_TRUNC('year', GETDATE() - INTERVAL '1 year')
    AND order_date < DATE_TRUNC('year', GETDATE())
GROUP BY
    customer_country
ORDER BY
    total_orders DESC
LIMIT
    1;-- Took (9th June): 183 ms, 105 ms, 86 ms, 95 ms, 84 ms
-- Next (9th June): 385 ms, 99 ms, 194 ms, 78 ms, 80 mss



-- As of today, for Q1 both versions performing well with similar times.
-- Q2: Slight advantage to default version
-- Q3: Clearly Opt version is performing better.
-- We will check for other business statements as well and then we can conclude.
-- In this project Priority is not given which means whichever version gives better results on more queries, that shall be the winner.



-- Q4
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_credit_def;
CREATE TABLE aws_project.temp_avg_credit_def AS
SELECT
    customer_country,
    AVG(customer_credit_rating) AS avg_credit_rating
FROM aws_project.order_transaction_def
GROUP BY
    customer_country;-- Took: 4.9s, 5.6s, 5.5s, 5.5s
-- Next Day (3rd June): 5.6s, 5.6s, 5.5s
-- Next Day (6th June): 8.1s, 5.5s, 5.4s
-- Next (7th June): 4.9s, 4s, 4.1s, 4.3s, 4.1s
-- Next (9th June): 5.8s, 4.5s, 4s, 4s, 4.2s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_credit_opt;
CREATE TABLE aws_project.temp_avg_credit_opt AS
SELECT
    customer_country,
    AVG(customer_credit_rating) AS avg_credit_rating
FROM aws_project.order_transaction_opt
GROUP BY
    customer_country;-- Took: 7.9s, 5.5s, 5.4s, 5.7s
-- Next Day (3rd June): 5.7s, 5.7s, 5.6s
-- Next Day (6th June): 8.2s, 5.5s, 5.6s
-- Next (7th June): 4.6s, 4.1s, 4.3s, 4.2s, 4.6s
-- Next (9th June): 6s, 4.1s, 4s, 4.6s, 4s



-- Q5
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_premium_ship_time_def;
CREATE TEMP TABLE temp_premium_ship_time_def AS
SELECT
    t.customer_state,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_shipment_days
FROM aws_project.order_transaction_def AS t
JOIN aws_project.order_shipment_def AS s
    ON t.order_id = s.order_id
WHERE
    t.customer_premium_flag = TRUE
GROUP BY
    t.customer_state;-- Took: 1m 13.1s, 57.4s, 57.3s, 56.7s
-- Next Day (3rd June): 1m 1.7s, 1m 2s, 1m 1.7s
-- Next Day (6th June): 1m 22.9s, 1m 2.3s, 1m 1.4s
-- Next (7th June): 1m 4.9s, 1m 3.9s, 1m 0.5s, 1m 4.1s, 57.8s
-- Next (9th June): 1m 6.2s, 1m 4s, 1m 3.6s, 1m 4.1s, 1m 3.8s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_premium_ship_time_opt;
CREATE TEMP TABLE temp_premium_ship_time_opt AS
SELECT
    t.customer_state,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_shipment_days
FROM aws_project.order_transaction_opt AS t
JOIN aws_project.order_shipment_opt AS s
    ON t.order_id = s.order_id
WHERE
    t.customer_premium_flag = TRUE
GROUP BY
    t.customer_state;-- Took: 1m 20s, 1m 1s, 1m 1.3s, 1m 1.4s
-- Next Day (3rd June): 1m 3.1s, 1m 3.3s, 1m 2.8s
-- Next Day (6th June): 1m 21s, 1m 3.2s, 1m 2.8s
-- Next (7th June): 1m 5.2s, 1m 0.1s, 1m 1.1s, 1m 5.4s, 1m 3.1s
-- Next (9th June): 1m 3.4s, 1m 0.5s, 1m, 1m 0.6s, 1m 0.7s



-- Q6
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_city_route_times_def;
CREATE TEMP TABLE temp_city_route_times_def AS
SELECT
    s.shipment_from_city,
    s.shipment_to_city,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_route_days,
    COUNT(*) AS total_shipments
FROM aws_project.order_transaction_def AS t
JOIN aws_project.order_shipment_def AS s
    ON t.order_id = s.order_id
GROUP BY
    s.shipment_from_city,
    s.shipment_to_city;-- Took: 2m 2.7s, 1m 59.2s, 1m 58s, 1m 58.2s
-- Next Day (3rd June): 2m 1.6s, 1m 59.6s, 1m 59.8s
-- Next Day (6th June): 2m 34.7s, 2m 0.7s, 1m 59.9s
-- Next (7th June): 1m 58.1s, 2m 2.2s, 2m 0.4s, 2m 3.6s, 2m 2.4s
-- Next (9th June): 2m 3.5s, 2m 2.5s, 2m 1.9s, 2m 3.1s, 2m 2s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_city_route_times_opt;
CREATE TEMP TABLE temp_city_route_times_opt AS
SELECT
    s.shipment_from_city,
    s.shipment_to_city,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_route_days,
    COUNT(*) AS total_shipments
FROM aws_project.order_transaction_opt AS t
JOIN aws_project.order_shipment_opt AS s
    ON t.order_id = s.order_id
GROUP BY
    s.shipment_from_city,
    s.shipment_to_city;-- Took: 2m 11.3s, 2m 0.5s, 1m 59.9s, 2m 0.5s
-- Next Day (3rd June): 1m 58.7s, 1m 58.9s, 1m 59.2s
-- Next Day (6th June): 3m 24.3s, 1m 59.3s, 1m 59.2s
-- Next (7th June): 2m 0.1s, 2m 0.8s, 2m 0.2s, 2m 3.2s, 2m 0.6s
-- Next (9th June): 1m 59.5s, 1m 59.6s, 1m 59.8s, 1m 59.6s, 1m 59.2s



-- Q7
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_lead_time_def;
CREATE TABLE aws_project.temp_avg_lead_time_def AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_def AS t
JOIN aws_project.order_shipment_def AS s
    ON t.order_id = s.order_id;-- Took: 1m 18.7s, 1m 17.5s, 1m 17.3s, 1m 16.9s
-- Next Day (3rd June): 4m 11.6s, 1m 13.7s, 1m 14.2s
-- Next Day (6th June): 2m 46.9s, 1m 13.8s, 1m 14s
-- Next (7th June): 1m 34.9s, 1m 16s, 1m 16.4s, 1m 31.3s, 1m 22.9s
-- Next (9th June): 1m 16s, 1m 15.8s, 1m 16s, 1m 15.7s, 1m 15.7s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_lead_time_opt;
CREATE TABLE aws_project.temp_avg_lead_time_opt AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_opt AS t
JOIN aws_project.order_shipment_opt AS s
    ON t.order_id = s.order_id;-- Took: 1m 15.1s, 1m 14s, 1m 14.6s, 1m 13.8s
-- Next Day (3rd June): 1m 53.3s, 1m 33.9s, 1m 33.2s
-- Next Day (6th June): 1m 14.2s, 1m 33.8s, 1m 33.6s
-- Next (7th June): 1m 14.4s, 1m 13.1s, 1m 13.7s, 1m 13.6s, 1m 13.3s
-- Next (9th June): 1m 14s, 1m 13.5s, 1m 13.2s, 1m 14s, 1m 13.1s



-- Q8
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_city_mismatches_def;
CREATE TEMP TABLE temp_city_mismatches_def AS
SELECT
    t.order_id,
    t.customer_id,
    t.customer_city,
    s.shipment_to_city
FROM aws_project.order_transaction_def AS t
JOIN aws_project.order_shipment_def AS s
    ON t.order_id = s.order_id
WHERE
    t.customer_city != s.shipment_to_city;-- Took: 2m 39.1s, 2m 31.9s, 2m 31.9s, 2m 31.8s
-- Next Day (3rd June): 3m 19.7s, 2m 48.6s, 2m 49.2s
-- Next Day (6th June): 2m 33s, 2m 48.9s, 2m 49.5s
-- Next (7th June): 2m 32.1s, 2m 32.2s, 2m 31.8s, 2m 32.1s, 2m 32.3s
-- Next (9th June): 1m 59.1s, 1m 58.7s, 1m 57.8s, 1m 57.3s, 1m 57.8s

UPDATE aws_project.order_shipment_def
SET shipment_to_city = t.customer_city
FROM aws_project.order_transaction_def t
WHERE
    aws_project.order_shipment_def.order_id = t.order_id
    AND aws_project.order_shipment_def.shipment_to_city != t.customer_city;--Took:

VACUUM FULL aws_project.order_shipment_def;-- Took: 32.5s
ANALYZE aws_project.order_shipment_def;-- Took: 1.2s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_city_mismatches_opt;
CREATE TEMP TABLE temp_city_mismatches_opt AS
SELECT
    t.order_id,
    t.customer_id,
    t.customer_city,
    s.shipment_to_city
FROM aws_project.order_transaction_opt AS t
JOIN aws_project.order_shipment_opt AS s
    ON t.order_id = s.order_id
WHERE
    t.customer_city != s.shipment_to_city;-- Took:  2m 52.9s, 2m 47.1s, 2m 47.1s, 2m 46.9s
-- Next Day (3rd June): 2m 52.4s, 2m 28.2s, 2m 27.7s
-- Next Day (6th June): 2m 48.7s, 2m 28.1s, 2m 28.1s
-- Next (7th June): 2m 46.9s, 2m 28s, 2m 28.1s, 2m 28.2s, 2m 28.1s
-- Next (9th June): 1m 52s, 1m 52.5s, 1m 52.1s, 1m 52.1s, 1m 51.7s

UPDATE aws_project.order_shipment_opt
SET shipment_to_city = t.customer_city
FROM aws_project.order_transaction_opt t
WHERE
    aws_project.order_shipment_opt.order_id = t.order_id
    AND aws_project.order_shipment_opt.shipment_to_city != t.customer_city;--Took:

VACUUM FULL aws_project.order_shipment_opt;-- Took: 10m 52s
ANALYZE aws_project.order_shipment_opt;-- Took: 1.1s



-- Q9
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_lead_time_amount_def;
CREATE TABLE aws_project.temp_lead_time_amount_def AS
SELECT
    CASE
        WHEN t.final_order_amount < 1000
            THEN 'Low (<1000)'
        WHEN t.final_order_amount BETWEEN 1000 AND 5000
            THEN 'Medium (1000-5000)'
        ELSE 'High (>5000)'
    END AS amount_bucket,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_def AS t
JOIN aws_project.order_shipment_def AS s
    ON t.order_id = s.order_id
GROUP BY
    1;-- Took: 1m 46.1s, 1m 46.1s, 1m 45.7s, 1m 46s
-- Next Day (3rd June): 2m 9.3s, 1m 32.2s, 1m 31.6s
-- Next Day (6th June): 1m 46.3s, 1m 33.5s, 1m 31s
-- Next (7th June): 1m 47.2s, 1m 29.5s, 1m 30s, 1m 29.9s, 1m 29.9s
-- Next (9th June): 1m 31.7s, 1m 30.8s, 1m 30.2s, 1m 30.7s, 1m 30.7s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_lead_time_amount_opt;
CREATE TABLE aws_project.temp_lead_time_amount_opt AS
SELECT
    CASE
        WHEN t.final_order_amount < 1000
            THEN 'Low (<1000)'
        WHEN t.final_order_amount BETWEEN 1000 AND 5000
            THEN 'Medium (1000-5000)'
        ELSE 'High (>5000)'
    END AS amount_bucket,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_opt AS t
JOIN aws_project.order_shipment_opt AS s
    ON t.order_id = s.order_id
GROUP BY
    1;-- Took: 1m 29.3s, 1m 29.2s, 1m 29.2s, 1m 29.2s
-- Next Day (3rd June): 2m 16.4s, 1m 23.6s, 1m 23.2s
-- Next Day (6th June): 1m 29.4s, 1m 32.6s, 1m 22.9s
-- Next (7th June): 1m 29.2s, 1m 29.2s, 1m 29.2s, 1m 29.3s, 1m 28.5s
-- Next (9th June): 1m 30.4s, 1m 29.6s, 1m 29s, 1m 28.7s, 1m 29.1s



-- Q10
-- --- DEFAULT VERSION ---
--DROP TABLE IF EXISTS aws_project.temp_top_states_premium_def;
--CREATE TABLE aws_project.temp_top_states_premium_def AS
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS premium_customer_count
FROM aws_project.order_transaction_def
WHERE
    customer_premium_flag = true
GROUP BY
    customer_state
ORDER BY
    premium_customer_count DESC
LIMIT
    20;-- Took: 8.4s, 7.8s, 7.7s, 8.7s
-- Next Day (3rd June): 26s, 8s, 8s
-- Next Day (6th June): 9.1s, 8.1s, 8s
-- Next (7th June): 8.4s, 7.7s, 7.2s, 7.3s, 7.4s
-- Next (9th June): 7 ms, 9 ms, 7 ms, 9 ms, 7 ms


-- --- OPTIMIZED VERSION ---
--DROP TABLE IF EXISTS aws_project.temp_top_states_premium_opt;
--CREATE TABLE aws_project.temp_top_states_premium_opt AS
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS premium_customer_count
FROM aws_project.order_transaction_opt
WHERE
    customer_premium_flag = true
GROUP BY
    customer_state
ORDER BY
    premium_customer_count DESC
LIMIT
    20;-- Took: 8s, 7.7s, 7.6s, 7.3s
-- Next Day (3rd June): 1m 20.8s, 8s, 8.2s
-- Next Day (6th June): 8.3s, 8s, 7.9s
-- Next (7th June): 8.2s, 7.7s, 7.8s, 7.8s, 8.1s
-- Next (9th June): 11 ms, 11 ms, 8 ms, 10 ms, 9 ms

/*
It seems
*/
