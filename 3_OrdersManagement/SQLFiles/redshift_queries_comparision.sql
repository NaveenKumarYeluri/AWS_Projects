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


-- As of today for Q1, both versions performing well with similar times.
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


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_credit_opt;
CREATE TABLE aws_project.temp_avg_credit_opt AS
SELECT
    customer_country,
    AVG(customer_credit_rating) AS avg_credit_rating
FROM aws_project.order_transaction_opt
GROUP BY
    customer_country;-- Took: 7.9s, 5.5s, 5.4s, 5.7s



-- Q5
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_premium_ship_time_def;
CREATE TEMP TABLE temp_premium_ship_time_def AS
SELECT
    t.customer_state,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_shipment_days
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id
WHERE
    t.customer_premium_flag = TRUE
GROUP BY
    t.customer_state;-- Took: 1m 13.1s, 57.4s, 57.3s, 56.7s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_premium_ship_time_opt;
CREATE TEMP TABLE temp_premium_ship_time_opt AS
SELECT
    t.customer_state,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_shipment_days
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id
WHERE
    t.customer_premium_flag = TRUE
GROUP BY
    t.customer_state;-- Took: 1m 20s, 1m 1s, 1m 1.3s, 1m 1.4s



-- Q6
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_city_route_times_def;
CREATE TEMP TABLE temp_city_route_times_def AS
SELECT
    s.shipment_from_city,
    s.shipment_to_city,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_route_days,
    COUNT(*) AS total_shipments
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id
GROUP BY
    s.shipment_from_city,
    s.shipment_to_city;-- Took: 2m 2.7s, 1m 59.2s, 1m 58s, 1m 58.2s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_city_route_times_opt;
CREATE TEMP TABLE temp_city_route_times_opt AS
SELECT
    s.shipment_from_city,
    s.shipment_to_city,
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_route_days,
    COUNT(*) AS total_shipments
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id
GROUP BY
    s.shipment_from_city,
    s.shipment_to_city;-- Took: 2m 11.3s, 2m 0.5s, 1m 59.9s, 2m 0.5s



-- Q7
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_lead_time_def;
CREATE TABLE aws_project.temp_avg_lead_time_def AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id;-- Took: 1m 18.7s, 1m 17.5s, 1m 17.3s, 1m 16.9s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_avg_lead_time_opt;
CREATE TABLE aws_project.temp_avg_lead_time_opt AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id;-- Took: 1m 15.1s, 1m 14s, 1m 14.6s, 1m 13.8s



-- Q8
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS temp_city_mismatches_def;
CREATE TEMP TABLE temp_city_mismatches_def AS
SELECT
    t.order_id,
    t.customer_id,
    t.customer_city,
    s.shipment_from_city
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id
WHERE
    t.customer_city != s.shipment_from_city;-- Took: 2m 39.1s, 2m 31.9s, 2m 31.9s, 2m 31.8s


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS temp_city_mismatches_opt;
CREATE TEMP TABLE temp_city_mismatches_opt AS
SELECT
    t.order_id,
    t.customer_id,
    t.customer_city,
    s.shipment_from_city
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id
WHERE
    t.customer_city != s.shipment_from_city;-- Took:  2m 52.9s, 2m 47.1s, 2m 47.1s, 2m 46.9s



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
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id
GROUP BY
    1;-- Took: 1m 46.1s, 1m 46.1s, 1m 45.7s, 1m 46s


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
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id
GROUP BY
    1;-- Took: 1m 29.3s, 1m 29.2s, 1m 29.2s, 1m 29.2s



-- Q10
-- --- DEFAULT VERSION ---
DROP TABLE IF EXISTS aws_project.temp_top_states_premium_def;
CREATE TABLE aws_project.temp_top_states_premium_def AS
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


-- --- OPTIMIZED VERSION ---
DROP TABLE IF EXISTS aws_project.temp_top_states_premium_opt;
CREATE TABLE aws_project.temp_top_states_premium_opt AS
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
