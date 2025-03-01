-- 1.a Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT *
FROM prescriber

SELECT * 
FROM prescription

SELECT npi, rx.total_claim_count AS total_claim_count
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
WHERE rx.total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 1;
-- the prescriber with npi 1912011792 had 4538 claims

-- 1.b Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT 
	npi, 
	rxer.nppes_provider_first_name, 
	rxer.nppes_provider_last_org_name, 
	rxer.specialty_description, 
	rx.total_claim_count AS total_claim_count
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
WHERE rx.total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 1;


-- 2.a  Which specialty had the most total number of claims (totaled over all drugs)?
SELECT rxer.specialty_description, SUM(rx.total_claim_count) AS claim_ct
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
WHERE rx.total_claim_count IS NOT NULL
GROUP BY rxer.specialty_description
ORDER BY claim_ct DESC
LIMIT 1;
-- family practice had the most claims at 9752347 claims

-- 2.b Which specialty had the most total number of claims for opioids?
SELECT drug_name
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE drug.opioid_drug_flag = 'Y'

SELECT rxer.specialty_description, SUM(rx.total_claim_count) AS claim_ct
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE drug_name IN (
	SELECT drug_name
	FROM prescriber AS rxer
	LEFT JOIN prescription AS rx
	USING(npi)
	LEFT JOIN drug
	USING(drug_name)
	WHERE drug.opioid_drug_flag = 'Y'
)
GROUP BY rxer.specialty_description
ORDER BY claim_ct DESC
LIMIT 1;
-- "Nurse Practitioner" has the most opiod related claims at 911350


-- 2.c **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT specialty_description
FROM prescriber
EXCEPT
SELECT DISTINCT p.specialty_description
FROM prescriber
INNER JOIN prescription
USING (npi)

--2.d **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- specialty & total_claim_ct
SELECT p.specialty_description, SUM(rx.total_claim_count)
FROM prescriber AS p
LEFT JOIN prescription AS rx
USING(npi)
LEFT JOIN drug AS d
USING(drug_name)
GROUP BY p.specialty_description

-- gets drug name, generic name, sum(total_claim), opioid drug flag
SELECT rx.drug_name, d.generic_name, SUM(rx.total_claim_count), d.opioid_drug_flag
FROM prescription AS rx
LEFT JOIN drug AS d
USING (drug_name)
GROUP BY rx.drug_name, d.generic_name, d.opioid_drug_flag
ORDER BY d.opioid_drug_flag DESC;

-- final selection! 
SELECT 
	p.specialty_description AS specialty,
	SUM(rx.total_claim_count) AS total_claims,
	SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN rx.total_claim_count ELSE 0 END)  * 100.0 / SUM(rx.total_claim_count) AS pct_opioids
FROM prescriber AS p
LEFT JOIN prescription AS rx
USING (npi)
LEFT JOIN drug AS d
USING (drug_name)
WHERE d.drug_name IS NOT NULL
GROUP BY p.specialty_description
ORDER BY total_claims DESC;

-- 3.a. Which drug (generic_name) had the highest total drug cost?
SELECT *
FROM prescription;

SELECT drug.generic_name AS drug, rx.total_drug_cost AS cost
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE drug.generic_name IS NOT NULL 
	AND rx.total_drug_cost IS NOT NULL
ORDER BY cost DESC
LIMIT 1;
-- "PIRFENIDONE" had the highest total drug cost at $2829174.3


-- 3.b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
	drug.generic_name AS drug, 
	rx.total_drug_cost AS cost,ROUND(rx.total_drug_cost / rx.total_day_supply, 2) AS cost_per_day
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE drug.generic_name IS NOT NULL 
	AND rx.total_drug_cost IS NOT NULL
	AND rx.total_day_supply IS NOT NULL
ORDER BY cost_per_day DESC
LIMIT 1;
-- highest cost per day is "IMMUN GLOB G(IGG)/GLY/IGA OV50" at $7141.11




-- 4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT 
	drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opiod'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug 

--4. b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	SUM(rx.total_drug_cost) AS MONEY, 
	CASE WHEN d.opioid_drug_flag = 'Y' THEN 'opiod'
	WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug AS d
LEFT JOIN prescription AS rx
USING(drug_name)
GROUP BY drug_type
ORDER BY MONEY DESC;

-- 5.a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT *
FROM cbsa

SELECT COUNT(cbsaname) AS n_tn
FROM cbsa
WHERE cbsaname LIKE '%, TN%';
--5.b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT *
FROM population 

SELECT *
FROM cbsa AS c
LEFT JOIN population AS pop
USING(fipscounty)
WHERE pop.population IS NOT NULL
ORDER BY pop.population DESC
LIMIT 1;
-- "Memphis, TN-MS-AR" had the highest population at 937847

SELECT *
FROM cbsa AS c
LEFT JOIN population AS pop
USING(fipscounty)
WHERE pop.population IS NOT NULL
ORDER BY pop.population ASC
LIMIT 1;

-- "Nashville-Davidson--Murfreesboro--Franklin, TN" had the smallest population at 8773


--5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT * 
FROM fips_county

SELECT *
FROM cbsa AS c
FULL JOIN fips_county AS fc
USING(fipscounty)
FULL JOIN population AS pop
USING(fipscounty)
WHERE pop.population IS NOT NULL
	AND cbsaname IS NULL
ORDER BY pop.population DESC
LIMIT 1;
-- Sevier county had the largest population and not included in CBSA


-- 6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT * 
FROM prescription

SELECT drug_name, total_claim_count
FROM prescription
GROUP BY drug_name, total_claim_count
HAVING total_claim_count >= 3000;



--6.b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
-- opiods

SELECT 
	drug_name, 
	total_claim_count,
	CASE WHEN drug_name IN (
	SELECT drug_name
	FROM prescriber AS rxer
	LEFT JOIN prescription AS rx
	USING(npi)
	LEFT JOIN drug
	USING(drug_name)
	WHERE drug.opioid_drug_flag = 'Y'
) THEN 'opioid' ELSE 'not' END AS is_opioid
FROM prescription as rx
LEFT JOIN prescriber AS rxer
USING(npi)
GROUP BY drug_name, total_claim_count
HAVING total_claim_count >= 3000;


--6.c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	npi, 
	rx.drug_name, 
	rx.total_claim_count,
	rxer.nppes_provider_first_name,
	rxer.nppes_provider_last_org_name,
	CASE WHEN rx.drug_name IN (
	SELECT drug_name
	FROM prescriber AS rxer
	LEFT JOIN prescription AS rx
	USING(npi)
	LEFT JOIN drug
	USING(drug_name)
	WHERE drug.opioid_drug_flag = 'Y'
) THEN 'opioid' ELSE 'not' END AS is_opioid
FROM prescription as rx
LEFT JOIN prescriber AS rxer
USING(npi)
GROUP BY 
	npi, 
	rx.drug_name, 
	rx.total_claim_count,
	rxer.nppes_provider_first_name,
	rxer.nppes_provider_last_org_name
HAVING rx.total_claim_count >= 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


--7.a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p.npi AS npi, d.drug_name AS drug
FROM prescriber AS p
CROSS JOIN drug AS d 
WHERE p.specialty_description = 'Pain Management'
	AND p.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y';


--7.b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT 
	rxer.npi,
	d.drug_name,
	SUM(rx.total_claim_count)
FROM prescriber AS rxer
LEFT JOIN prescription AS rx
USING(npi)
CROSS JOIN drug AS d
WHERE rxer.specialty_description = 'Pain Management'
	AND rxer.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
GROUP BY rxer.npi, d.drug_name
ORDER BY rxer.npi DESC;

	
--7.c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 
	rxer.npi,
	d.drug_name,
	COALESCE(SUM(rx.total_claim_count), 0) AS total_claim_count
FROM prescriber AS rxer
CROSS JOIN drug AS d
LEFT JOIN prescription AS rx
USING(npi)
WHERE rxer.specialty_description = 'Pain Management'
	AND rxer.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
GROUP BY rxer.npi, d.drug_name
ORDER BY rxer.npi DESC;
