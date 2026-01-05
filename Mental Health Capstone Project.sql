Update [social performance.mhl]
	   Set Diagnosis = TRIM(Diagnosis)
		  
		  
--Number of people with diagnosis in each country, excluding people with no diagnosed disorder
Select pf.Country,
	   COUNT(sp.diagnosis) Total_Diagnosis
From [personal info.mhl] pf
Join [social performance.mhl] sp
	 On pf.User_ID = sp.User_ID
Where sp.Diagnosis Not Like 'None'
Group by pf.Country
Order by Total_Diagnosis desc

--The average sleep hours, average work hours and total stress of each country.
With StressHabits As
(Select sb.User_ID, 
		AVG(sp.Work_Hours_per_Week) Work_Hrs,
	    AVG(sb.sleep_hours) Avg_Sleep_Time,
	   SUM(Case when stress_level = 'Low' then 1
				when Stress_Level = 'Moderate' then 2
				when Stress_Level = 'High' then 3
				Else 0
				End) Total_Stress
From [social behaviour.mhl] sb Join [social performance.mhl] sp On sb.User_ID = sp.User_ID
Group by sb.User_ID)
Select pf.Country, 
	   AVG(sh.Avg_Sleep_Time) Avg_Sleep_Time, 
	   SUM(sh.Total_Stress) Total_Stress, 
	   AVG(sh.Work_Hrs) Avg_Work_Hrs
From [personal info.mhl] pf
Join StressHabits sh On pf.User_ID = sh.User_ID
Group by pf.Country

--The happiness level and exercise rate of each diagnosis
Select sp.Diagnosis,
	   AVG(sp.happiness_level) Happiness_Level, 
	   SUM(CASE WHEN exercise_level = 'High' THEN 3
	   WHEN exercise_level = 'Moderate' THEN 2
	   WHEN exercise_level = 'Low' THEN 1
	   ELSE 0 END) Exercise_Rate
From [social performance.mhl] sp
Join [social behaviour.mhl] sb
	 On sp.User_ID = sb.User_ID
Group by Diagnosis
order by Exercise_Rate desc

--Analyse how social interaction and happiness level affects diagnosis, showing their rank.
select a.Diagnosis,
	   a.Avg_Happiness_Rate,
	   ROW_NUMBER() Over (Order By a.Avg_Happiness_Rate desc) Happiness_Rank,
	   a.Avg_Soc_Int,
	   ROW_NUMBER() Over (Order By a.Avg_Soc_Int desc) Soc_Int_Rank
from (Select Diagnosis, 
	  AVG(Happiness_Level) Avg_Happiness_Rate,
	  AVG(Social_Interaction) Avg_Soc_Int
	  From [social performance.mhl]
	  Group by Diagnosis) a

--The most frequent diet type for each country
WITH AllCountries AS (
    SELECT DISTINCT Country FROM [personal info.mhl]),
DietFrequencies AS (
SELECT pf.Country, sb.Diet_Type,
       COUNT(*) AS DietFreq
FROM [social behaviour.mhl] sb
JOIN [personal info.mhl] pf ON sb.user_id = pf.user_id
GROUP BY pf.Country, sb.Diet_Type),
RankedDiets AS (
SELECT c.Country, df.Diet_Type, df.DietFreq,
       ROW_NUMBER() OVER (PARTITION BY c.Country ORDER BY df.DietFreq DESC) AS FrequencyRank
FROM AllCountries c
LEFT JOIN DietFrequencies df ON c.Country = df.Country)
SELECT Country, Diet_Type, DietFreq, FrequencyRank
FROM RankedDiets
WHERE FrequencyRank = 1 OR (FrequencyRank IS NULL AND Diet_Type IS NULL)

--The average happiness rate and average social interaction for each diagnosis. Including the ranks.
select a.Diagnosis,
	   a.Avg_Happiness_Rate,
	   ROW_NUMBER() Over (Order By a.Avg_Happiness_Rate desc) Happiness_Rank,
	   a.Avg_Soc_Int,
	   ROW_NUMBER() Over (Order By a.Avg_Soc_Int desc) Soc_Int_Rank
from (Select Diagnosis, 
	  AVG(Happiness_Level) Avg_Happiness_Rate,
	  AVG(Social_Interaction) Avg_Soc_Int
	  From [social performance.mhl]
	  Group by Diagnosis) a

--Total number of each gender affected by various diagnoses.
SELECT Diagnosis,
	   SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS Male,
       SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS Female,
       SUM(CASE WHEN gender = 'Other' THEN 1 ELSE 0 END) AS Other,
       COUNT(*) AS Total
FROM [personal info.mhl] pf
Join [social performance.mhl] sp On pf.user_ID = sp.user_ID
WHERE Diagnosis IN ('Anxiety', 'PTSD', 'None', 'Depression', 'Bipolar')
    AND gender IS NOT NULL
GROUP BY Diagnosis
ORDER BY Total desc