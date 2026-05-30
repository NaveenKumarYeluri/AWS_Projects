-- 1)

SELECT DISTINCT
    flight_id,
    -- distance / speed
    CAST((distance / NULLIF(avg_flight_speed_kmps, 0)) / 60 AS DECIMAL(10,2)) AS flight_duration_mins
FROM aws_project.Fact_Flight_Transactions
WHERE
    distance IS NOT NULL
    AND avg_flight_speed_kmps IS NOT NULL;


-- 2)

SELECT
    origin_airport,
    destination_airport,
    COUNT(ticket_no) AS total_passengers
FROM aws_project.Fact_Flight_Transactions
GROUP BY
    origin_airport,
    destination_airport
ORDER BY
    total_passengers DESC
LIMIT 1;


-- 3)

WITH All_City_Interactions AS (
    SELECT
        flight_id,
        origin_airport AS city_airport
    FROM aws_project.Fact_Flight_Transactions

    UNION ALL

    SELECT
        flight_id,
        destination_airport AS city_airport
    FROM aws_project.Fact_Flight_Transactions
)
SELECT
    city_airport,
    COUNT(flight_id) AS total_unique_flights
FROM All_City_Interactions
GROUP BY
    city_airport
ORDER BY
    total_unique_flights DESC
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
    WHERE
        avg_flight_speed_kmps IS NOT NULL
        AND distance IS NOT NULL
    GROUP BY
        airplane_model
)
SELECT
    airplane_model,
    total_unique_flights,
    CAST(
        (n * sum_xy - sum_x * sum_y) /
        NULLIF(SQRT((n * sum_x2 - (sum_x * sum_x)) * (n * sum_y2 - (sum_y * sum_y))), 0)
    AS DECIMAL(5,4)) AS correlation_score
FROM stats
WHERE
    total_unique_flights > 50
ORDER BY
    correlation_score DESC;


-- 6)

SELECT
    airplane_model,
    -- Total Distance / Total Fuel
    CAST(
        SUM(distance) / NULLIF(SUM(fuel_consumed_litre), 0)
    AS DECIMAL(10,2)) AS fule_economy,
    COUNT(DISTINCT flight_id) AS total_flights
FROM aws_project.Fact_Flight_Transactions
WHERE
    distance IS NOT NULL
    AND fuel_consumed_litre IS NOT NULL
GROUP BY
    airplane_model
ORDER BY
    fule_economy DESC
LIMIT 20;


-- 7)

WITH total_tickets AS (
    SELECT
        d.year AS flight_year,
        COUNT(f.ticket_no) AS frequent_fliers_cnt
    FROM aws_project.Fact_Flight_Transactions AS f
    INNER JOIN Dim_Date AS d
        ON d.date_sk = f.date_fk
    WHERE
        f.frequent_flier_status = 1
    GROUP BY
        d.year
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
WHERE
    engine_performance IS NOT NULL
    AND distance IS NOT NULL
GROUP BY
    airplane_model;
ORDER BY
    avg_rpm_per_km AVG
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
    WHERE
        fuel_consumed_litre IS NOT NULL
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
WHERE
    passenger_country IS NOT NULL
GROUP BY
    passenger_country
ORDER BY
    tickets_per_country DESC
LIMIT 5;


-- 13)

WITH age_calculation AS (
    SELECT
        ticket_no,
        DATEDIFF('year', passenger_dob, CURRENT_DATE) AS age
    FROM aws_project.Fact_Flight_Transactions
    WHERE
        passenger_dob IS NOT NULL
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
GROUP BY
    age_group
ORDER BY
    age_group ASC;


-- 14)

WITH age_calculation AS (
    SELECT
        ticket_no,
        passenger_flight_class,
        DATEDIFF('year', passenger_dob, CURRENT_DATE) AS age
    FROM aws_project.Fact_Flight_Transactions
    WHERE
        passenger_flight_class IS NOT NULL
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
GROUP BY
    age_group,
    passenger_flight_class
ORDER BY
    age_group ASC,
    passenger_flight_class ASC;


-- 15)

/*
-------------------------------------------------------------------------
-- NOTE: Data profiling reveals a ~1:1 ratio between total
-- tickets and unique flight_ids.
-- The dataset does not support answering this question.
-------------------------------------------------------------------------
*/


-- 16)

SELECT
    origin_airport,
    destination_airport,
    CAST(AVG(flight_cost) AS DECIMAL(10, 2)) AS avg_route_cost,
    COUNT(ticket_no) AS total_tickets_sold
FROM aws_project.Fact_Flight_Transactions
WHERE
    flight_cost IS NOT NULL
    AND origin_airport IS NOT NULL
    AND destination_airport IS NOT NULL
GROUP BY
    origin_airport,
    destination_airport
ORDER BY
    origin_airport,
    avg_route_cost DESC;


-- 17)

SELECT
    d.calendar_year,
    d.calendar_month,
    CAST(AVG(f.fuel_consumed_litre) AS DECIMAL(10, 2)) AS avg_fuel_per_yr_mnth
FROM aws_project.Fact_Flight_Transactions AS f
INNER JOIN aws_project.Dim_Date AS d
    ON d.date_sk = f.date_fk
WHERE
    f.fuel_consumed_litre IS NOT NULL
    AND d.calendar_year IS NOT NULL
    AND d.calendar_month IS NOT NULL
GROUP BY
    d.calendar_year,
    d.calendar_month
ORDER BY
    d.calendar_year ASC,
    d.calendar_month ASC;


SELECT
    EXTRACT(YEAR FROM travel_date) AS calendar_year,
    EXTRACT(MONTH FROM travel_date) AS calendar_month,
    CAST(AVG(fuel_consumed_litre) AS DECIMAL(10, 2)) AS avg_fuel_per_month
FROM aws_project.Fact_Flight_Transactions
WHERE
    fuel_consumed_litre IS NOT NULL
    AND travel_date IS NOT NULL
GROUP BY
    EXTRACT(YEAR FROM travel_date),
    EXTRACT(MONTH FROM travel_date)
ORDER BY
    calendar_year ASC,
    calendar_month ASC;


-- 18)

SELECT
    origin_airport,
    destination_airport,
    MAX(turbulence) AS max_turbulence
FROM aws_project.Fact_Flight_Transactions
WHERE
    turbulence IS NOT NULL
    AND origin_airport IS NOT NULL
    AND destination_airport IS NOT NULL
GROUP BY
    origin_airport,
    destination_airport
ORDER BY
    max_turbulence DESC
LIMIT 1;


-- 19)

WITH landing_flights AS (
    SELECT
        destination_airport,
        EXTRACT(YEAR FROM travel_date) AS travel_year,
        COUNT(flight_id) AS total_landings,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM travel_date)
            ORDER BY COUNT(flight_id) DESC
        ) AS land_rank
    FROM aws_project.Fact_Flight_Transactions
    WHERE
        destination_airport IS NOT NULL
        AND travel_date IS NOT NULL
    GROUP BY
        destination_airport,
        EXTRACT(YEAR FROM travel_date)
)
SELECT
    travel_year,
    destination_airport AS busiest_airport,
    total_landings
FROM landing_flights
WHERE
    land_rank = 1
ORDER BY
    travel_year ASC;


-- 20)

WITH All_Airport_Movements AS (
    SELECT
        origin_airport AS airport,
        EXTRACT(YEAR FROM departure_time) AS movement_year,
        flight_id
    FROM aws_project.Fact_Flight_Transactions
    WHERE
        origin_airport IS NOT NULL
        AND departure_time IS NOT NULL

    UNION ALL

    SELECT
        destination_airport AS airport,
        EXTRACT(YEAR FROM travel_date) AS movement_year,
        flight_id
    FROM aws_project.Fact_Flight_Transactions
    WHERE
        destination_airport IS NOT NULL
        AND travel_date IS NOT NULL
),
Yearly_Rankings AS (
    SELECT
        airport,
        movement_year,
        COUNT(flight_id) AS total_movements,
        ROW_NUMBER() OVER (
            PARTITION BY movement_year
            ORDER BY COUNT(flight_id) DESC
        ) AS traffic_rank
    FROM All_Airport_Movements
    GROUP BY
        airport,
        movement_year
)
SELECT
    movement_year,
    airport AS busiest_airport,
    total_movements
FROM Yearly_Rankings
WHERE
    traffic_rank = 1
ORDER BY
    movement_year ASC;
