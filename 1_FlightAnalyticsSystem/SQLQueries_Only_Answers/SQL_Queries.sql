-- 1)

SELECT DISTINCT
    flight_id,
    -- distance / speed
    CAST((distance / NULLIF(avg_flight_speed_kmps, 0)) / 60 AS DECIMAL(10,2)) AS flight_duration_mins
FROM aws_project.Fact_Flight_Transactions
WHERE distance IS NOT NULL
AND avg_flight_speed_kmps IS NOT NULL;


-- 2)

SELECT
    origin_airport,
    destination_airport,
    COUNT(ticket_no) AS total_passengers
FROM aws_project.Fact_Flight_Transactions
GROUP BY origin_airport, destination_airport
ORDER BY total_passengers DESC
LIMIT 1;


-- 3)

WITH All_City_Interactions AS (
    SELECT flight_id, origin_airport AS city_airport
    FROM aws_project.Fact_Flight_Transactions

    UNION ALL

    SELECT flight_id, destination_airport AS city_airport
    FROM aws_project.Fact_Flight_Transactions
)
SELECT
    city_airport,
    COUNT(flight_id) AS total_unique_flights
FROM All_City_Interactions
GROUP BY city_airport
ORDER BY total_unique_flights DESC
LIMIT 10;


-- 4)

SELECT
    origin_airport,
    destination_airport,
    CAST(AVG(turbulence) AS DECIMAL(5,2)) AS avg_turbulence_score
FROM aws_project.Fact_Flight_Transactions
GROUP BY
    origin_airport,
    destination_airport
ORDER BY
    avg_turbulence_score DESC
LIMIT 10;


-- 5)

WITH stats AS (
    SELECT
        airplane_model,
        COUNT(DISTINCT flight_id) AS total_unique_flights,
        COUNT(*) AS n,
        SUM(CAST(avg_flight_speed_kmps AS FLOAT8)) AS sum_x,
        SUM(CAST(distance AS FLOAT8)) AS sum_y,
        SUM(CAST(avg_flight_speed_kmps AS FLOAT8) * CAST(distance AS FLOAT8)) AS sum_xy,
        SUM(CAST(avg_flight_speed_kmps AS FLOAT8) * CAST(avg_flight_speed_kmps AS FLOAT8)) AS sum_x2,
        SUM(CAST(distance AS FLOAT8) * CAST(distance AS FLOAT8)) AS sum_y2
    FROM aws_project.Fact_Flight_Transactions
    WHERE avg_flight_speed_kmps IS NOT NULL
      AND distance IS NOT NULL
    GROUP BY airplane_model
)
SELECT
    airplane_model,
    total_unique_flights,
    CAST(
        (n * sum_xy - sum_x * sum_y) /
        NULLIF(SQRT((n * sum_x2 - (sum_x * sum_x)) * (n * sum_y2 - (sum_y * sum_y))), 0)
    AS DECIMAL(5,4)) AS correlation_score
FROM stats
WHERE total_unique_flights > 50
ORDER BY correlation_score DESC;


-- 6)

SELECT
    airplane_model,
    -- Total Distance / Total Fuel
    CAST(
        SUM(distance) / NULLIF(SUM(fuel_consumed_litre), 0)
    AS DECIMAL(10,2)) AS fule_economy,
    COUNT(DISTINCT flight_id) AS total_flights
FROM aws_project.Fact_Flight_Transactions
WHERE distance IS NOT NULL
AND fuel_consumed_litre IS NOT NULL
GROUP BY airplane_model
ORDER BY fule_economy DESC
LIMIT 20;


-- 7)

WITH total_tickets AS (
    SELECT
        d.year AS flight_year,
        COUNT(f.ticket_no) AS frequent_fliers_cnt
    FROM aws_project.Fact_Flight_Transactions AS f
    INNER JOIN Dim_Date AS d
        ON d.date_sk = f.date_fk
    WHERE f.frequent_flier_status = 1
    GROUP BY d.year
),
per_year_tickets_cnt AS (
    SELECT
        flight_year,
        frequent_fliers_cnt,
        LAG(frequent_fliers_cnt) OVER (ORDER BY flight_year) AS prev_year_cnt
    FROM total_tickets
)
SELECT
    flight_year,
    frequent_fliers_cnt,
    prev_year_cnt,
    -- (current_year_cnt - previous_year_cnt / previous_year_cnt) * 100
    ROUND(
        (frequent_fliers_cnt - prev_year_cnt)::FLOAT
        / NULLIF(prev_year_cnt, 0) * 100,
    2) AS yoy_percentage_change
FROM per_year_tickets_cnt;


-- 8)

/*
-------------------------------------------------------------------------
-- NOTE: This cannot be answered as the present dataset
-- does not have the required columns or data granularity to support
-- the calculation.
-------------------------------------------------------------------------
*/


--9)

/*
-------------------------------------------------------------------------
-- NOTE: This cannot be answered as the present dataset
-- does not have the required columns or data granularity to support
-- the calculation.
-------------------------------------------------------------------------
*/


-- 10)

SELECT
    airplane_model,
    COUNT(DISTINCT flight_id) AS total_flights,
    CAST(
        SUM(engine_performance) / NULLIF(SUM(distance), 0)
    AS DECIMAL(10, 2)
    ) AS avg_rpm_per_km
FROM aws_project.Fact_Flight_Transactions
WHERE engine_performance IS NOT NULL
AND distance IS NOT NULL
GROUP BY airplane_model;
ORDER BY avg_rpm_per_km AVG
LIMIT 10;


-- 11)

WITH stats AS (
    SELECT
        COUNT(*) AS n,
        SUM(CAST(fuel_consumed_litre AS FLOAT8)) AS sum_x,
        SUM(CAST(distance AS FLOAT8)) AS sum_y,
        SUM(CAST(fuel_consumed_litre AS FLOAT8) * CAST(distance AS FLOAT8)) AS sum_xy,
        SUM(CAST(fuel_consumed_litre AS FLOAT8) * CAST(fuel_consumed_litre AS FLOAT8)) AS sum_x2,
        SUM(CAST(distance AS FLOAT8) * CAST(distance AS FLOAT8)) AS sum_y2
    FROM aws_project.Fact_Flight_Transactions
    WHERE fuel_consumed_litre IS NOT NULL
      AND distance IS NOT NULL
)
SELECT
    CAST(
        (n * sum_xy - sum_x * sum_y) /
        NULLIF(SQRT((n * sum_x2 - (sum_x * sum_x)) * (n * sum_y2 - (sum_y * sum_y))), 0)
    AS DECIMAL(5,4)) AS fuel_distance_correlation
FROM stats;


-- 12)

SELECT
    passenger_country,
    COUNT(ticket_no) as tickets_per_country
FROM aws_project.Fact_Flight_Transactions
WHERE passenger_country IS NOT NULL
GROUP BY passenger_country
ORDER BY tickets_per_country DESC
LIMIT 5;


-- 13)

WITH age_calculation AS (
    SELECT
        ticket_no,
        DATEDIFF('year', passenger_dob, CURRENT_DATE) AS age
    FROM aws_project.Fact_Flight_Transactions
    WHERE passenger_dob IS NOT NULL
)
SELECT
    CASE
        WHEN age <= 23 THEN '1. Young'
        WHEN age <= 38 THEN '2. Adult'
        WHEN age <= 55 THEN '3. Senior Adult'
        ELSE '4. Older'
    END AS age_group,
    COUNT(ticket_no) AS total_flights_taken
FROM age_calculation
GROUP BY age_group
ORDER BY age_group ASC;


-- 14)

WITH age_calculation AS (
    SELECT
        ticket_no,
        passenger_flight_class,
        DATEDIFF('year', passenger_dob, CURRENT_DATE) AS age
    FROM aws_project.Fact_Flight_Transactions
    WHERE passenger_flight_class IS NOT NULL
    AND passenger_dob IS NOT NULL
),
create_age_groups AS (
    SELECT
        ticket_no,
        passenger_flight_class,
        CASE
            WHEN age <= 23
                THEN '1. Young (0-23)'
            WHEN age <= 38
                THEN '2. Adult (24-38)'
            WHEN age <= 55
                THEN '3. Senior Adult (39-55)'
            ELSE '4. Older (56+)'
        END AS age_group
    FROM age_calculation
)
SELECT
    age_group,
    passenger_flight_class,
    COUNT(ticket_no) AS total_tickets
FROM create_age_groups
GROUP BY age_group, passenger_flight_class
ORDER BY age_group ASC, passenger_flight_class ASC;


