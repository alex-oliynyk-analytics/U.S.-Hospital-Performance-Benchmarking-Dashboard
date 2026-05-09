-- =====================================================
-- Project:  U.S. Hospital Performance Benchmarking
-- Author:   Alex Oliynyk
-- Data:     CMS Timely and Effective Care Dataset
-- Tool:     SQLite / DB Browser for SQLite
-- GitHub:   github.com/alex-oliynyk-analytics
-- =====================================================

-- =====================================================
-- 1. Create Clean Base Table
-- =====================================================

DROP TABLE IF EXISTS healthcare_clean;

CREATE TABLE healthcare_clean AS
SELECT
    "Facility ID",
    "Facility Name",
    State,
    Condition,
    "Measure ID",
    "Measure Name",
    CAST(Score AS FLOAT) AS Score
FROM healthcare_dataset
WHERE Score IS NOT NULL
AND Score != ''
AND Score != 'Not Available'
AND State IS NOT NULL
AND State != ''
AND "Facility ID" IS NOT NULL
AND "Facility ID" != ''
AND "Facility Name" IS NOT NULL
AND "Facility Name" != ''
AND CAST(Score AS FLOAT) > 0;


-- =====================================================
-- 2. Remove Incompatible Emergency Department Metrics
-- =====================================================

DROP TABLE IF EXISTS healthcare_final;

CREATE TABLE healthcare_final AS
SELECT *
FROM healthcare_clean
WHERE "Measure Name" NOT LIKE '%Emergency Department%'
AND "Measure Name" NOT LIKE '%median time%'
AND "Measure Name" NOT LIKE '%department volume%';


-- =====================================================
-- 3. Final Tableau Export Table
-- =====================================================

DROP TABLE IF EXISTS healthcare_final_v2;

CREATE TABLE healthcare_final_v2 AS
SELECT *
FROM healthcare_final
WHERE Score > 0;


-- =====================================================
-- 4. Total Reporting Hospitals
-- =====================================================

SELECT COUNT(DISTINCT "Facility ID") AS reporting_hospitals
FROM healthcare_final_v2;


-- =====================================================
-- 5. National Average Score
-- =====================================================

SELECT ROUND(AVG(Score), 2) AS national_avg_score
FROM healthcare_final_v2;


-- =====================================================
-- 6. Active Measure Count
-- =====================================================

SELECT COUNT(DISTINCT "Measure Name") AS active_measure_count
FROM healthcare_final_v2;


-- =====================================================
-- 7. Available Measures and Hospital Counts
-- =====================================================

SELECT
    Condition,
    "Measure Name",
    COUNT(DISTINCT "Facility ID") AS hospital_count,
    ROUND(AVG(Score), 2) AS avg_score
FROM healthcare_final_v2
GROUP BY Condition, "Measure Name"
ORDER BY hospital_count DESC;


-- =====================================================
-- 8. Top 10 Hospitals by Selected Measure
-- =====================================================

SELECT
    "Facility Name",
    State,
    ROUND(AVG(Score), 2) AS avg_score
FROM healthcare_final_v2
WHERE "Measure Name" = 'Appropriate care for severe sepsis and septic shock'
GROUP BY "Facility Name", State
ORDER BY avg_score DESC
LIMIT 10;


-- =====================================================
-- 9. Bottom 10 Hospitals by Selected Measure
-- =====================================================

SELECT
    "Facility Name",
    State,
    ROUND(AVG(Score), 2) AS avg_score
FROM healthcare_final_v2
WHERE "Measure Name" = 'Appropriate care for severe sepsis and septic shock'
GROUP BY "Facility Name", State
ORDER BY avg_score ASC
LIMIT 10;


-- =====================================================
-- 10. State Map Verification Query
-- =====================================================

SELECT
    State,
    COUNT(DISTINCT "Facility ID") AS hospitals_reporting,
    ROUND(AVG(Score), 2) AS avg_score
FROM healthcare_final_v2
WHERE "Measure Name" = 'Appropriate care for severe sepsis and septic shock'
GROUP BY State
ORDER BY avg_score DESC;

-- =====================================================
-- 11. State Performance Ranking (Window Function)
-- =====================================================
SELECT
    State,
    ROUND(AVG(Score), 2) AS avg_score,
    COUNT(DISTINCT "Facility ID") AS hospitals_reporting,
    RANK() OVER (ORDER BY AVG(Score) DESC) AS state_rank
FROM healthcare_final_v2
WHERE "Measure Name" = 'Appropriate care for severe sepsis and septic shock'
GROUP BY State
ORDER BY state_rank;

-- =====================================================
-- 12. Hospital Performance Tiers by Measure
-- =====================================================
SELECT
    "Facility Name",
    State,
    ROUND(AVG(Score), 2) AS avg_score,
    CASE
        WHEN AVG(Score) >= 90 THEN 'High Performer'
        WHEN AVG(Score) >= 70 THEN 'Average Performer'
        WHEN AVG(Score) >= 50 THEN 'Below Average'
        ELSE 'Low Performer'
    END AS performance_tier
FROM healthcare_final_v2
WHERE "Measure Name" = 'Appropriate care for severe sepsis and septic shock'
GROUP BY "Facility Name", State
ORDER BY avg_score DESC;
