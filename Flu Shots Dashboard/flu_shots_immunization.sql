/*
Objectives
Come up with flu shots dashboard for 2022 that does the following

1.) Total % of patients getting flu shots stratified by
	a.) Age
	b.) Race
	c.) County (On a Map)
	d.) Overall
2.) Running Total of Flu Shots over the course of 2022
3.) Total number of Flu shots given in 2022
4.) A list of Patients that show whether or not they received the flu shots

Requirements:

Patients must have been "Active at our hospital"
*/

SELECT *
FROM patients;

SELECT pat.birthdate
      ,pat.race
	  ,pat.county
	  ,pat.id
	  ,pat.first
	  ,pat.last
	  ,EXTRACT(YEAR FROM age('12-31-2022', birthdate)) AS age
FROM patients AS pat;

SELECT *
FROM immunizations;

-- Some patients may have received more than one flu vaccine during the year 2022
SELECT patient, MIN(date) AS earliest_flu_shot_2022
FROM immunizations
WHERE code = '5302' -- Corresponds to Seasonal Flu Vaccine
  AND date BETWEEN '2022-01-01 00:00' AND '2022-12-31 23:59' -- Including timeframe ensures that the entire day for 12-31 is not missed
GROUP BY patient;

-- Creating a CTE in this way to ensure a one-to-one join
-- Prevents duplicating rows in a one-to-many join
WITH flu_shot_2022 AS
(
SELECT patient, MIN(date) AS earliest_flu_shot_2022
FROM immunizations
WHERE code = '5302' -- Corresponds to Seasonal Flu Vaccine
  AND date BETWEEN '2022-01-01 00:00' AND '2022-12-31 23:59'
GROUP BY patient
)
SELECT pat.birthdate
      ,pat.race
	  ,pat.county
	  ,pat.id
	  ,pat.first
	  ,pat.last
	  ,flu.earliest_flu_shot_2022
	  ,flu.patient
	  ,CASE
	       WHEN flu.patient IS NOT NULL THEN 1
		   ELSE 0
	   END AS flu_shot_2022
FROM patients AS pat
LEFT JOIN flu_shot_2022 AS flu
  ON pat.id = flu.patient;

/* 
Need to account for active patients (i.e., those not deceased or who've moved away)
Active patients we can assume are patients who've had an encounter within the past two years
*/
SELECT *
FROM encounters;

SELECT patient,
FROM encounters AS e
JOIN patients AS pat
  ON e.patient = pat.id
WHERE start BETWEEN '2022-01-01 00:00' AND '2022-12-31 23:59';



-- (Recommended guideline) Patients 6 months and older should be receiving the flu shot every year
SELECT DISTINCT patient
FROM encounters AS e
JOIN patients AS pat
  ON e.patient = pat.id
WHERE start BETWEEN '2020-01-01 00:00' AND '2022-12-31 23:59'
 AND pat.deathdate IS NULL
 AND EXTRACT(MONTH FROM age('2022-12-31', pat.birthdate)) >= 6;
-- Error: ^ filter doesn't give the actual months in their age instead should've used EXTRACT(EPOCH FROM age('2022-12-31',pat.birthdate)) / 2592000


WITH active_patients AS
(
SELECT DISTINCT patient
FROM encounters AS e
JOIN patients AS pat
  ON e.patient = pat.id
WHERE start BETWEEN '2020-01-01 00:00' AND '2022-12-31 23:59'
 AND pat.deathdate IS NULL
 AND EXTRACT(MONTH FROM age('2022-12-31', pat.birthdate)) >= 6
),

flu_shot_2022 AS
(
SELECT patient, MIN(date) AS earliest_flu_shot_2022
FROM immunizations
WHERE code = '5302' -- Corresponds to Seasonal Flu Vaccine
  AND date BETWEEN '2022-01-01 00:00' AND '2022-12-31 23:59'
GROUP BY patient
)
SELECT pat.birthdate
      ,pat.race
	  ,pat.county
	  ,pat.id
	  ,pat.first
	  ,pat.last
	  ,flu.earliest_flu_shot_2022
	  ,flu.patient
	  ,CASE
	       WHEN flu.patient IS NOT NULL THEN 1
		   ELSE 0
	   END AS flu_shot_2022
FROM patients AS pat
LEFT JOIN flu_shot_2022 AS flu
  ON pat.id = flu.patient
WHERE 1=1
  AND pat.id IN (SELECT patient FROM active_patients);  --The patient id must be in the CTE active_patients from earlier