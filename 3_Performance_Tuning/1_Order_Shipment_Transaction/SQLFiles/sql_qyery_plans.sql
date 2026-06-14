-- Q10
-- --- DEFAULT VERSION ---
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
-- Next Day (3rd June): 26s, 8s, 8s


/*
Step - 1
-> XN Seq Scan on order_transaction_def order_transaction_def_1 (cost=0.00..3125000.00 rows=124632620 width=20)
Scans 124632620 rows on "order_transaction_def" table

Step - 2
-> XN HashAggregate (cost=3748163.10..3748163.10 rows=5479499 width=20)
Operator for unsorted grouped aggregate functions.

Step - 3
-> XN HashAggregate (cost=3830355.59..3830356.09 rows=200 width=176)
Operator for unsorted grouped aggregate functions.

Step - 4
Sort Key: count(new_agg)
Sorted by count(new_agg).

Step - 5
-> XN Network (cost=1000003830363.73..1000003830364.23 rows=200 width=176)
Sends intermediate results to the leader node for further processing.

Step - 6
Merge Key: count(new_agg)
Final sorted results according to intermediate sorted results that are produced by parallel operations using count(new_agg).

Step - 7
XN Limit (cost=1000003830363.73..1000003830363.78 rows=20 width=176)
Processes the LIMIT clause.
*/


-- --- OPTIMIZED VERSION ---
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
-- Next Day (3rd June): 1m 20.8s, 8s, 8.2s


/*
Step - 1
-> XN Seq Scan on order_transaction_opt order_transaction_opt_1 (cost=0.00..3125000.00 rows=125000000 width=176)
Scans 125000000 rows on "order_transaction_opt" table

Step - 2
-> XN HashAggregate (cost=3750000.00..3750000.00 rows=20000 width=176)
Operator for unsorted grouped aggregate functions.

Step - 3
-> XN HashAggregate (cost=3750300.00..3750300.50 rows=200 width=176)
Operator for unsorted grouped aggregate functions.

Step - 4
Sort Key: count(new_agg)
Sorted by count(new_agg).

Step - 5
-> XN Network (cost=1000003750308.14..1000003750308.64 rows=200 width=176)
Sends intermediate results to the leader node for further processing.

Step - 6
Merge Key: count(new_agg)
Final sorted results according to intermediate sorted results that are produced by parallel operations using count(new_agg).

Step - 7
XN Limit (cost=1000003750308.14..1000003750308.19 rows=20 width=176)
Processes the LIMIT clause.
*/



-- Q9
-- --- DEFAULT VERSION ---
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
-- Next Day (3rd June): 2m 9.3s, 1m 32.2s, 1m 31.6s


/*
Step - 1
-> XN Seq Scan on order_shipment_def s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_def" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_def t (cost=0.00..2500000.00 rows=250000000 width=38)
Scans 250000000 rows on "order_transaction_def" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_INNER (cost=3240403.41..154407742469.07 rows=249999041 width=24)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. The inner table is redistributed.

Step - 6
XN HashAggregate (cost=154408992464.27..154409001411.32 rows=715764 width=24)
Operator for unsorted grouped aggregate functions.
*/


-- --- OPTIMIZED VERSION ---
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
-- Next Day (3rd June): 2m 16.4s, 1m 23.6s, 1m 23.2s


/*
Step - 1
-> XN Seq Scan on order_shipment_opt s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_opt" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_opt t (cost=0.00..2500000.00 rows=250000000 width=38)
Scans 250000000 rows on "order_transaction_opt" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_NONE (cost=3240403.41..8280069.07 rows=249999041 width=24)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. No tables are redistributed; collocated joins are possible (without moving data between nodes).

Step - 6
XN HashAggregate (cost=9530064.27..9530066.77 rows=200 width=24)
Operator for unsorted grouped aggregate functions.
*/



-- Q8
-- --- DEFAULT VERSION ---
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
-- Next Day (3rd June): 3m 19.7s, 2m 48.6s, 2m 49.2s


/*
Step - 1
-> XN Seq Scan on order_shipment_def s (cost=0.00..2499990.40 rows=249999040 width=35)
Scans 249999040 rows on "order_shipment_def" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=35)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_def t (cost=0.00..2500000.00 rows=250000000 width=43)
Scans 250000000 rows on "order_transaction_def" table

Step - 4
Join Filter: (("inner".shipment_from_city)::text <> ("outer".customer_city)::text)
Join filter: ("inner".shipment_from_city)::text <> ("outer".customer_city)::text.

Step - 5
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 6
XN Hash Join DS_DIST_INNER (cost=3245286.20..168405818751.64 rows=249858392 width=56)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. The inner table is redistributed.
*/


-- --- OPTIMIZED VERSION ---
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
-- Next Day (3rd June): 2m 52.4s, 2m 28.2s, 2m 27.7s


/*
Step - 1
-> XN Seq Scan on order_shipment_opt s (cost=0.00..2499990.40 rows=249999040 width=35)
Scans 249999040 rows on "order_shipment_opt" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=35)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_opt t (cost=0.00..2500000.00 rows=250000000 width=198)
Scans 250000000 rows on "order_transaction_opt" table

Step - 4
Join Filter: (("inner".shipment_from_city)::text <> ("outer".customer_city)::text)
Join filter: ("inner".shipment_from_city)::text <> ("outer".customer_city)::text.

Step - 5
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 6
XN Hash Join DS_DIST_NONE (cost=3245286.20..6410111.64 rows=249858354 width=211)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. No tables are redistributed; collocated joins are possible (without moving data between nodes).
*/



-- Q7
-- --- DEFAULT VERSION ---
CREATE TABLE aws_project.temp_avg_lead_time_def AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_def t
JOIN aws_project.order_shipment_def s
    ON t.order_id = s.order_id;-- Took: 1m 18.7s, 1m 17.5s, 1m 17.3s, 1m 16.9s
-- Next Day (3rd June): 4m 11.6s, 1m 13.7s, 1m 14.2s


/*
Step - 1
-> XN Seq Scan on order_shipment_def s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_def" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_def t (cost=0.00..2500000.00 rows=250000000 width=30)
Scans 250000000 rows on "order_transaction_def" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_INNER (cost=3240403.41..154405867476.26 rows=249999041 width=16)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. The inner table is redistributed.
*/


-- --- OPTIMIZED VERSION ---
CREATE TABLE aws_project.temp_avg_lead_time_opt AS
SELECT
    AVG(DATEDIFF(day, t.order_date, s.shipment_date)) AS avg_lead_time_days
FROM aws_project.order_transaction_opt t
JOIN aws_project.order_shipment_opt s
    ON t.order_id = s.order_id;-- Took: 1m 15.1s, 1m 14s, 1m 14.6s, 1m 13.8s
-- Next Day (3rd June): 1m 53.3s, 1m 33.9s, 1m 33.2s


/*
Step - 1
-> XN Seq Scan on order_shipment_opt s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_opt" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_opt t (cost=0.00..2500000.00 rows=250000000 width=30)
Scans 250000000 rows on "order_transaction_opt" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_NONE (cost=3240403.41..6405076.26 rows=249999041 width=16)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. No tables are redistributed; collocated joins are possible (without moving data between nodes).
*/



-- Q6
-- --- DEFAULT VERSION ---
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
-- Next Day (3rd June): 2m 1.6s, 1m 59.6s, 1m 59.8s


/*
Step - 1
-> XN Seq Scan on order_transaction_def t (cost=0.00..2500000.00 rows=250000000 width=30)
Scans 250000000 rows on "order_transaction_def" table

Step - 2
-> XN Hash (cost=2500000.00..2500000.00 rows=250000000 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_shipment_def s (cost=0.00..2499990.40 rows=249999040 width=56)
Scans 249999040 rows on "order_shipment_def" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_OUTER (cost=3240415.75..238405544916.45 rows=249999041 width=42)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. The outer table is redistributed.

Step - 6
XN HashAggregate (cost=238408044906.86..238408068589.82 rows=3157729 width=42)
Operator for unsorted grouped aggregate functions.
*/


-- --- OPTIMIZED VERSION ---
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
-- Next Day (3rd June): 1m 58.7s, 1m 58.9s, 1m 59.2s


/*
Step - 1
-> XN Seq Scan on order_transaction_opt t (cost=0.00..2500000.00 rows=250000000 width=30)
Scans 250000000 rows on "order_transaction_opt" table

Step - 2
-> XN Hash (cost=2500000.00..2500000.00 rows=250000000 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_shipment_opt s (cost=0.00..2499990.40 rows=249999040 width=56)
Scans 249999040 rows on "order_shipment_opt" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_NONE (cost=3240415.75..6405076.45 rows=249999041 width=42)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. No tables are redistributed; collocated joins are possible (without moving data between nodes).

Step - 6
XN HashAggregate (cost=8905066.86..8928749.82 rows=3157729 width=42)
Operator for unsorted grouped aggregate functions.
*/



-- Q5
-- --- DEFAULT VERSION ---
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
-- Next Day (3rd June): 1m 1.7s, 1m 2s, 1m 1.7s


/*
Step - 1
-> XN Seq Scan on order_transaction_def t (cost=0.00..3125000.00 rows=124632620 width=42)
Scans 124632620 rows on "order_transaction_def" table

Step - 2
-> XN Hash (cost=3125000.00..3125000.00 rows=124632620 width=42)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_shipment_def s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_def" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_OUTER (cost=3494254.01..154406121008.64 rows=124632621 width=28)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. The outer table is redistributed.

Step - 6
XN HashAggregate (cost=154406744171.74..154406744171.87 rows=25 width=28)
Operator for unsorted grouped aggregate functions.
*/


-- --- OPTIMIZED VERSION ---
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
-- Next Day (3rd June): 1m 3.1s, 1m 3.3s, 1m 2.8s


/*
Step - 1
-> XN Seq Scan on order_shipment_opt s (cost=0.00..2499990.40 rows=249999040 width=30)
Scans 249999040 rows on "order_shipment_opt" table

Step - 2
-> XN Hash (cost=2499990.40..2499990.40 rows=249999040 width=30)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys.

Step - 3
-> XN Seq Scan on order_transaction_opt t (cost=0.00..3125000.00 rows=125000000 width=198)
Scans 125000000 rows on "order_transaction_opt" table

Step - 4
Hash Cond: (("outer".order_id)::text = ("inner".order_id)::text)
Hash condition: (("outer".order_id)::text = ("inner".order_id)::text).

Step - 5
-> XN Hash Join DS_DIST_NONE (cost=3240403.41..6697739.84 rows=125000001 width=184)
A hash join and hash are used for inner joins, left outer joins, right outer joins. These operators are used when joining tables where the join columns aren't distribution keys and sort keys. No tables are redistributed; collocated joins are possible (without moving data between nodes).

Step - 6
XN HashAggregate (cost=7322739.84..7322740.34 rows=100 width=184)
Operator for unsorted grouped aggregate functions.
*/



-- Q4
-- --- DEFAULT VERSION ---
CREATE TABLE aws_project.temp_avg_credit_def AS
SELECT
    customer_country,
    AVG(customer_credit_rating) AS avg_credit_rating
FROM aws_project.order_transaction_def
GROUP BY
    customer_country;-- Took: 4.9s, 5.6s, 5.5s, 5.5s
-- Next Day (3rd June): 5.6s, 5.6s, 5.5s


/*
Step - 1
-> XN Seq Scan on order_transaction_def (cost=0.00..2500000.00 rows=250000000 width=21)
Scans 250000000 rows on "order_transaction_def" table

Step - 2
XN HashAggregate (cost=3750000.00..3750000.63 rows=252 width=21)
Operator for unsorted grouped aggregate functions.
*/


-- --- OPTIMIZED VERSION ---
CREATE TABLE aws_project.temp_avg_credit_opt AS
SELECT
    customer_country,
    AVG(customer_credit_rating) AS avg_credit_rating
FROM aws_project.order_transaction_opt
GROUP BY
    customer_country;-- Took: 7.9s, 5.5s, 5.4s, 5.7s
-- Next Day (3rd June): 5.7s, 5.7s, 5.6s


/*
Step - 1
-> XN Seq Scan on order_transaction_opt (cost=0.00..2500000.00 rows=250000000 width=21)
Scans 250000000 rows on "order_transaction_opt" table

Step - 2
XN HashAggregate (cost=3750000.00..3750000.63 rows=252 width=21)
Operator for unsorted grouped aggregate functions.
*/



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
-- Next Day (2nd June) Runs: 12783 ms, 10656 ms, 8183 ms, 8181 ms, 8177 ms
-- Next Day (3rd June): 5539 ms, 5373 ms, 5370 ms


/*
Step - 1
-> XN Seq Scan on order_transaction_def (cost=0.00..3750000.00 rows=372981 width=35)
Scans 372981 rows on "order_transaction_def" table

Step - 2
-> XN HashAggregate (cost=3751864.91..3751864.91 rows=1 width=35)
Operator for unsorted grouped aggregate functions.

Step - 3
Sort Key: count(order_id)
Sorted by count(order_id).

Step - 4
-> XN Network (cost=1000003751864.92..1000003751864.92 rows=1 width=35)
Sends intermediate results to the leader node for further processing.

Step - 5
Merge Key: count(order_id)
Final sorted results according to intermediate sorted results that are produced by parallel operations using count(order_id).

Step - 6
XN Limit (cost=1000003751864.92..1000003751864.92 rows=1 width=35)
Processes the LIMIT clause.
*/


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
-- Next Day (2nd June) Runs: 1289 ms, 939 ms, 968 ms, 975 ms, 271 ms
-- Next Day (3rd June): 396 ms, 193 ms, 190 ms


/*
Step - 1
-> XN Seq Scan on order_transaction_opt (cost=0.00..4026.13 rows=268409 width=35)
Scans 268409 rows on "order_transaction_opt" table

Step - 2
-> XN HashAggregate (cost=5368.18..5368.18 rows=1 width=35)
Operator for unsorted grouped aggregate functions.

Step - 3
Sort Key: count(order_id)
Sorted by count(order_id).

Step - 4
-> XN Network (cost=1000000005368.19..1000000005368.19 rows=1 width=35)
Sends intermediate results to the leader node for further processing.

Step - 5
Merge Key: count(order_id)
Final sorted results according to intermediate sorted results that are produced by parallel operations using count(order_id).

Step - 6
XN Limit (cost=1000000005368.19..1000000005368.19 rows=1 width=35)
Processes the LIMIT clause.
*/



-- Q2:
-- RUN AGAINST DEFAULT VERSION:
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


/*
Step - 1
-> XN Seq Scan on order_transaction_def (cost=0.00..2500000.00 rows=250000000 width=16)
Scans 250000000 rows on "order_transaction_def" table

Step - 2
-> XN HashAggregate (cost=5000000.00..5000673.72 rows=89830 width=16)
Operator for unsorted grouped aggregate functions.

Step - 3
Sort Key: customer_credit_rating
Sorted by customer_credit_rating.
*/


-- RUN AGAINST OPTIMIZED VERSION:
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


/*
Step - 1
-> XN Seq Scan on order_transaction_opt (cost=0.00..2500000.00 rows=250000000 width=16)
Scans 250000000 rows on "order_transaction_opt" table

Step - 2
-> XN HashAggregate (cost=5000000.00..5000673.72 rows=89830 width=16)
Operator for unsorted grouped aggregate functions.

Step - 3
Sort Key: customer_credit_rating
Sorted by customer_credit_rating.
*/



-- Q1:
-- RUN AGAINST DEFAULT VERSION:
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


/*
Step - 1
-> XN Seq Scan on order_transaction_def (cost=0.00..3750000.00 rows=152636707 width=46)
Scans 152636707 rows on "order_transaction_def" table

Step - 2
Sort Key: customer_id, order_date
Sorted by customer_id, order_date.
*/


-- RUN AGAINST OPTIMIZED VERSION:
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


/*
Step - 1
-> XN Seq Scan on order_transaction_opt (cost=0.00..2300401.20 rows=153360080 width=46)
Scans 153360080 rows on "order_transaction_opt" table

Step - 2
Sort Key: customer_id, order_date
Sorted by customer_id, order_date.
*/


