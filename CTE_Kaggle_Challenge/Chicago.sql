
--For the two Kaggle Data Challenge questions, I imported the necessary data into a table called chicago_salary
--I want to determine the department, annual_salary, standard deviation, average, and z-score for the salary date
--using this data, we can determine the following: salary disparity, budget allocation, incentive programs, and adjusting accordingly.


WITH DepartmentStats AS (
    SELECT
        department,
        annual_salary,
        ROUND(STDDEV(annual_salary) OVER (PARTITION BY department), 2) AS StandardDeviation,
        ROUND(AVG(annual_salary) OVER (PARTITION BY department), 2) AS Average
    FROM Chicago_salary
)
SELECT
    department,
    annual_salary,
    StandardDeviation,
    Average,
    (annual_salary - Average) / NULLIF(StandardDeviation, 0) AS Zscore
FROM DepartmentStats

