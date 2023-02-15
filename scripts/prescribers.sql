-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC
LIMIT 1;

-- Answer: npi 1912011792 claim count 4538

SELECT p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description, p2.total_claim_count
FROM prescriber AS p
JOIN prescription AS p2
	USING (npi)
ORDER BY total_claim_count DESC
LIMIT 1;

-- Answer: DAVID COFFEY, Family Practice, had 4538

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
	

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

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

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.