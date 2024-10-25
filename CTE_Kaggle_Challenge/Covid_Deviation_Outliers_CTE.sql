
--Using CTE, the following query creates a number of statistics for understanding Covid deaths by country
--stats: Standard Deviation, Average, Coefficient_Variation, and Outliers
--We can use this data to determine outliers by country, policy and resource allocation
 --A high standard deviation suggests greater variability in death counts

WITH CovidStats AS (
    SELECT
        country,
        ROUND(STDDEV(total_deaths), 2) AS StandardDeviation,
        ROUND(AVG(total_deaths), 2) AS Average
    FROM coviddeaths
    GROUP BY country
),
Vacs AS (
    SELECT
        cd.country,
        cd.total_deaths,
        cs.StandardDeviation,
        cs.Average,
        (cd.total_deaths - cs.Average) / NULLIF(cs.StandardDeviation, 0) AS Zscore
    FROM coviddeaths cd
    JOIN CovidStats cs ON cd.country = cs.country
)

SELECT
    cd.country,
    cd.StandardDeviation,
    cd.Average,
    CASE
    	WHEN cd.Average = 0 THEN NULL
    	ELSE ROUND(cd.StandardDeviation / cd.Average, 2)
    END AS Coefficient_of_Variation,
    SUM(CASE WHEN v.Zscore > 1.96 OR v.Zscore < -1.96 THEN 1 ELSE 0 END) AS Outlier_Count
FROM CovidStats cd
LEFT JOIN Vacs v ON cd.country = v.country
GROUP BY cd.country, cd.StandardDeviation, cd.Average, cd.Average
ORDER BY cd.country;

