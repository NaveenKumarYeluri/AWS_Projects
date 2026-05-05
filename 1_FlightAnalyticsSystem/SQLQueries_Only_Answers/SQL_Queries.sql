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
