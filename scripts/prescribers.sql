-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT npi, SUM(total_claim_count) AS count
FROM prescription
GROUP BY npi
ORDER BY count DESC
LIMIT 1;

-- Answer: npi 1912011792 claim count 4538

SELECT p.nppes_provider_first_name AS first_name, p.nppes_provider_last_org_name AS last_name, 
	p.specialty_description AS description, SUM(p2.total_claim_count) AS claims
FROM prescriber AS p
JOIN prescription AS p2
	USING (npi)
GROUP BY first_name, last_name, description
ORDER BY claims DESC
LIMIT 1;

-- Answer: BRUCE PENDLEY, Family Practice, had 99707

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT p.specialty_description, SUM(p2.total_claim_count) AS total_claims
FROM prescriber AS p
INNER JOIN prescription AS p2
	USING (npi)
	GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- Answer a: Family practice with 9,752,347

--     b. Which specialty had the most total number of claims for opioids?

SELECT p.specialty_description, COUNT(d.opioid_drug_flag) AS opioids
FROM prescriber AS p
INNER JOIN prescription
	USING (npi)
INNER JOIN drug AS d
	USING (drug_name)
GROUP BY p.specialty_description
ORDER BY opioids DESC
LIMIT 1;

-- Answer b: Nurse Practitioner with 175734 opioid claims.

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT p.specialty_description
FROM prescriber AS p
LEFT JOIN prescription AS p2
	USING (npi)
	GROUP BY p.specialty_description
	HAVING SUM(p2.total_claim_count) IS NULL;
	
-- Answer 2c: there are 15 specialties

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH all_opioids AS
	(SELECT p.specialty_description, 
	SUM(p2.total_claim_count) AS op_claims
	FROM prescription AS p2
	INNER JOIN prescriber AS p
	USING (npi)
	INNER JOIN drug AS d
 	USING (drug_name)
	WHERE d.opioid_drug_flag = 'Y'
	GROUP BY p.specialty_description),
	all_claims AS 
	(SELECT p.specialty_description,
	SUM(p2.total_claim_count) AS t_claims
	FROM prescription AS p2
	INNER JOIN prescriber AS p
	USING (npi)
	INNER JOIN drug AS d
	USING (drug_name)
	GROUP BY p.specialty_description)
SELECT p.specialty_description, 
	ROUND(AVG(o.op_claims/t.t_claims),5) AS pertotal
FROM prescriber AS p
	INNER JOIN all_opioids AS o
	ON p.specialty_description = o.specialty_description
	INNER JOIN all_claims AS t
	ON p.specialty_description = t.specialty_description
	GROUP BY p.specialty_description
	ORDER BY pertotal DESC;

-- Answer 2d: The seven highest have over 50% opioids.  Those are: "Case Manager/Care Coordinator" "Orthopaedic Surgery", "Interventional Pain Management", "Anesthesiology", "Pain Management", "Hand Surgery" and "Surgical Oncology"

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT d.generic_name AS generic,
	SUM(p.total_drug_cost) AS cost
FROM drug AS d
INNER JOIN prescription AS p
	USING (drug_name)
	GROUP BY generic
	ORDER BY cost DESC
	LIMIT 1;
	
-- Answer a: INSULIN GLARGINE,HUM.REC.ANLOG cost 104264066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT d.generic_name AS name,
	CAST(ROUND(SUM(p.total_drug_cost)/COUNT(p.total_day_supply),2) AS MONEY) AS daily_cost
FROM drug AS d
INNER JOIN prescription AS p
	USING (drug_name)
	GROUP BY name
	ORDER BY daily_cost DESC
	LIMIT 1;
	
-- Answer 3b: 	ASFOTASE ALFA cost $1,890,733.05

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, 
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type,
	CAST(SUM(p.total_drug_cost) AS MONEY)
FROM drug AS d
LEFT JOIN prescription AS p
	USING (drug_name)
	GROUP BY drug_type;
	
-- Answer 4b: Opioids had $105,080,626.37, antibiotics had $38,435,121.26

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(c.cbsa) 
FROM cbsa AS c
INNER JOIN fips_county AS f
 USING (fipscounty)
 WHERE f.state = 'TN';
 
-- Answer 5a: There are 42.

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa AS c
INNER JOIN population AS p
	USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop;

-- Answer 5b: Largest CBSA is Nashville-Davidson--Murfreesboro--Franklin, TN with 1830410.  The Smallest CBSA is Morristown, TN with 116352.           

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT p.fipscounty, county, SUM(population) AS total_pop, cbsaname
	FROM population AS p
	INNER JOIN fips_county
		USING (fipscounty)
	LEFT JOIN cbsa
		USING (fipscounty)
GROUP BY p.fipscounty, county, cbsaname
ORDER BY cbsaname DESC, total_pop DESC;

-- Answer 5c: SEVIER 95523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY drug_name;

-- Answer 6a: there are 9.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS drug_type
FROM prescription
	INNER JOIN drug
	USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY drug_name;

-- Answer 6b: Two are listed as opioids HYDROCODONE-ACETAMINOPHEN and OXYCODONE HCL


--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name AS firstname,
	nppes_provider_last_org_name AS lastname, 
	drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS drug_type
FROM prescription
	INNER JOIN drug
	USING (drug_name)
	INNER JOIN prescriber
	USING (npi)
WHERE total_claim_count >= 3000
ORDER BY drug_type DESC;

-- Answer 6c: David Coffey wrote both opiods.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p1.npi, d.drug_name
FROM prescriber AS p1
CROSS JOIN drug AS d
WHERE p1.specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y'
	AND nppes_provider_city = 'NASHVILLE';
	
--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT p1.npi, d.drug_name, SUM(total_claim_count)
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
	ON d.drug_name = p2.drug_name
WHERE p1.specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y'
	AND nppes_provider_city = 'NASHVILLE'
	GROUP BY p1.npi, d.drug_name
	ORDER BY npi, drug_name;	
	
   
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT p1.npi, d.drug_name, COALESCE(SUM(total_claim_count),0)
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
	ON d.drug_name = p2.drug_name
WHERE p1.specialty_description = 'Pain Management'
	AND opioid_drug_flag = 'Y'
	AND nppes_provider_city = 'NASHVILLE'
	GROUP BY p1.npi, d.drug_name
	ORDER BY npi, drug_name;

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(p.npi) AS not_on_rx
FROM prescriber AS p
LEFT JOIN prescription AS rx
	ON p.npi = rx.npi
	WHERE rx.npi IS NULL;
	
-- BONUS 1: There are 4458 not on the prescription table.

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.


SELECT d.generic_name, SUM(total_claim_count) AS claims
FROM prescription AS rx
INNER JOIN drug AS d
	USING (drug_name)
INNER JOIN prescriber AS p
	USING (npi)
WHERE p.specialty_description = 'Family Practice'
	GROUP BY d.generic_name
	ORDER BY claims DESC
	LIMIT 5;
	
-- BONUS 2a: LEVOTHYROXINE SODIUM with 406547, LISINOPRIL with 311506, ATORVASTATIN CALCIUM with 308523,
-- 			AMLODIPINE BESYLATE with 304343, OMEPRAZOLE with 273570

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT d.generic_name, SUM(total_claim_count) AS claims
FROM prescription AS rx
INNER JOIN drug AS d
	USING (drug_name)
INNER JOIN prescriber AS p
	USING (npi)
WHERE p.specialty_description = 'Cardiology'
	GROUP BY d.generic_name
	ORDER BY claims DESC
	LIMIT 5;

-- BONUS 2b: "ATORVASTATIN CALCIUM" "CARVEDILOL" "METOPROLOL TARTRATE" "CLOPIDOGREL BISULFATE" "AMLODIPINE BESYLATE"

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT d.generic_name, SUM(total_claim_count) AS claims
FROM prescription AS rx
INNER JOIN drug AS d
	USING (drug_name)
INNER JOIN prescriber AS p
	USING (npi)
WHERE p.specialty_description = 'Family Practice'
	OR p.specialty_description = 'Cardiologist'
	GROUP BY d.generic_name
	ORDER BY claims DESC
	LIMIT 5;
	
-- BONUS 2c: "LEVOTHYROXINE SODIUM" "LISINOPRIL" "ATORVASTATIN CALCIUM" "AMLODIPINE BESYLATE" "OMEPRAZOLE"

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
SELECT p.npi, p.nppes_provider_city, SUM (rx.total_claim_count) AS total_claims
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN zip_fips AS z
	ON p.nppes_provider_zip5 = z.zip
INNER JOIN cbsa AS c
	ON z.fipscounty = c.fipscounty
WHERE c.cbsa = '34980'
GROUP BY p.npi, p.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


--     b. Now, report the same for Memphis.

SELECT p.npi, p.nppes_provider_city, SUM (rx.total_claim_count) AS total_claims
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN zip_fips AS z
	ON p.nppes_provider_zip5 = z.zip
INNER JOIN cbsa AS c
	ON z.fipscounty = c.fipscounty
WHERE c.cbsa = '32820'
GROUP BY p.npi, p.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT p.npi, p.nppes_provider_city, c.cbsaname, SUM (rx.total_claim_count) AS total_claims
FROM prescriber AS p
INNER JOIN prescription AS rx
	USING (npi)
INNER JOIN zip_fips AS z
	ON p.nppes_provider_zip5 = z.zip
INNER JOIN cbsa AS c
	ON z.fipscounty = c.fipscounty
WHERE c.cbsa = '16860'
	OR c.cbsa = '28940'
	OR c.cbsa = '32820'
	OR c.cbsa = '34980'
GROUP BY p.npi, p.nppes_provider_city, c.cbsaname
ORDER BY total_claims DESC
LIMIT 15;


-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

