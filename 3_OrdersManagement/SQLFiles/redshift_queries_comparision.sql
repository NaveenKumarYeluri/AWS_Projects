-- We will be creating a temp table for queries which are going to fecth load of records,
-- so the query time cannot be obstructed by network or client rendering.
-- We will be disabling result cache as well.

SET enable_result_cache_for_session TO off;

-- Q1:
-- RUN AGAINST DEFAULT VERSION:
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


-- RUN AGAINST OPTIMIZED VERSION:
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



-- Q2:
-- RUN AGAINST DEFAULT VERSION:
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


-- RUN AGAINST OPTIMIZED VERSION:
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



-- Q3:
-- RUN AGAINST DEFAULT VERSION:
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


-- RUN AGAINST OPTIMIZED VERSION:
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

-- As of today for Q1 both versions performing well with similar times.
-- Q2: Slight advantage to default version
-- Q3: Clearly Opt version is performing better.
-- We will check for other business statements as well and then we can conclude.
-- In this project Priority is not given which means whichever version gives better results on more queries, that shall be the winner.
