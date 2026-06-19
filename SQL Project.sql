create database my_database;
use my_database;
-- Convert the Date fields to Natural Time
SELECT 
	ProjectID, 
    FROM_UNIXTIME(created_at) AS created_date, 
    FROM_UNIXTIME(deadline) AS deadline_date, 
    FROM_UNIXTIME(updated_at) AS updated_date,
    FROM_UNIXTIME(state_changed_at) AS state_changed_at,
    FROM_UNIXTIME(successful_at) AS successful_at,
    FROM_UNIXTIME(launched_at) AS launched_at
FROM projects;
-- Build a Calendar Table using the Date Column 
CREATE TABLE calendar (
    calendar_date DATE PRIMARY KEY,
    year INT,
    monthno INT,
    monthfullname VARCHAR(20),
    quarter VARCHAR(3),
    yearmonth VARCHAR(20),
    weekdayno INT,
    weekdayname VARCHAR(10),
    financial_month VARCHAR(5),
    financial_quarter VARCHAR(5)
);
SET SESSION cte_max_recursion_depth = 5000;
INSERT INTO calendar
WITH RECURSIVE Calendar AS (
    SELECT DATE(FROM_UNIXTIME(MIN(created_at))) AS Date
    FROM Projects
    UNION ALL
    SELECT DATE_ADD(Date, INTERVAL 1 DAY)
    FROM Calendar
    WHERE Date < (SELECT DATE(FROM_UNIXTIME(MAX(created_at))) FROM Projects)
)
SELECT 
    Date,
    YEAR(Date) AS Year,
    MONTH(Date) AS MonthNo,
    MONTHNAME(Date) AS MonthFullName,
    CONCAT('Q', QUARTER(Date)) AS Quarter,
    CONCAT(YEAR(Date), '-', LEFT(MONTHNAME(Date), 3)) AS YearMonth,
    DAYOFWEEK(Date) AS WeekdayNo,
    DAYNAME(Date) AS WeekdayName,
    CONCAT('FM', (MONTH(Date) - 3 + 12) % 12 + 1) AS FinancialMonth,
    CONCAT('FQ', CEIL(((MONTH(Date) - 3 + 12) % 12 + 1) / 3)) AS FinancialQuarter
FROM Calendar;
select * from calendar;

-- Goal amount into USD
SELECT 
    projectID, 
    goal * 1.18 AS goal_amount_usd  
FROM projects;

--  Total Number of Projects based on outcome
SELECT state, COUNT(*) AS total_projects FROM projects GROUP BY state;

-- Total Number of Projects created by Year , Quarter , Month
SELECT 
    c.year, 
    c.quarter, 
    c.monthfullname, 
    COUNT(p.projectID) AS total_projects
FROM projects p
JOIN calendar c 
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
WHERE p.created_at IS NOT NULL
GROUP BY c.year, c.quarter, c.monthfullname
ORDER BY c.year, c.quarter, c.monthfullname;

-- 

SELECT SUM(pledged) AS total_amount_raised FROM projects WHERE state = 'successful';

--  Successful Projects by Number of Backers

SELECT SUM(backers_count) AS total_backers FROM projects WHERE state = 'successful';

-- Avg NUmber of Days for successful projects
SELECT AVG(DATEDIFF(FROM_UNIXTIME(deadline), FROM_UNIXTIME(created_at))) AS avg_days_success 
FROM projects WHERE state = 'successful';

--  Top 10  Successful Projects :Based on Number of Backers
SELECT name, backers_count FROM projects WHERE state = 'successful' ORDER BY backers_count DESC LIMIT 10;

--   Successful Projects Based on Amount Raised.
SELECT name, pledged FROM projects WHERE state = 'successful' ORDER BY pledged DESC LIMIT 10;

-- 
SELECT 
    (COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100 / COUNT(*)) AS success_percentage
FROM projects;
--  Percentage of Successful projects by Goal Range
SELECT 
    goal,
    COUNT(*) AS total_projects,
    COUNT(CASE WHEN state = 'successful' THEN 1 END) AS successful_projects,
    ROUND((COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(*)), 2) AS success_percentage
FROM (
    SELECT 
        projectID,
        state,
        CASE 
            WHEN goal < 1000 THEN 'Low (0-1K)'
            WHEN goal BETWEEN 1000 AND 5000 THEN 'Medium (1K-5K)'
            ELSE 'High (5K+)'
        END AS goal
    FROM projects
) AS grouped_projects
GROUP BY goal;
