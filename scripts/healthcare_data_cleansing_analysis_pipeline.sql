-- =====================================================================
-- PURPOSE: Clean and analyze healthcare dataset through multiple steps:
--          1. Standardize patient names to Proper Case
--          2. Deduplicate records (full duplicates and age variations)
--          3. Create unique Patient IDs and Visit IDs
--          4. Standardize billing amounts to 2 decimal places
--          5. Perform comprehensive data analysis
-- SOURCE:  healthcare_dataset table
-- TARGET:  Updated healthcare_dataset table with clean data and IDs
-- KEY TRANSFORMATIONS:
--   - Name standardization (Proper Case)
--   - Duplicate removal (full duplicates and age variations)
--   - Patient ID assignment based on name, blood type, and age range
--   - Visit ID assignment for each admission
--   - Billing amount rounding to 2 decimal places
-- =====================================================================

-- =====================================================================
-- PART 1: DATA CLEANING AND STANDARDIZATION
-- =====================================================================

-- 1.1 Standardize patient names to Proper Case format
UPDATE healthcare_dataset
SET name = 
    UPPER(LEFT(name, 1)) + 
    LOWER(SUBSTRING(name, 2, ISNULL(NULLIF(CHARINDEX(' ', name), 0), LEN(name) + 1) - 1)) +
    CASE 
        WHEN CHARINDEX(' ', name) > 0 THEN
            ' ' + UPPER(SUBSTRING(name, CHARINDEX(' ', name) + 1, 1)) + 
            LOWER(SUBSTRING(name, CHARINDEX(' ', name) + 2, LEN(name)))
        ELSE ''
    END;


-- 1.2 Identify duplicate entries (test query for specific patient)
WITH Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission,
                Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number,
                Admission_Type, Discharge_Date, Medication, Test_Results
            ORDER BY Date_of_Admission
        ) AS flag
    FROM healthcare_dataset
    WHERE name = 'Abigail Young'
)
SELECT * 
FROM Duplicates
WHERE flag > 1;


-- 1.3 Delete all duplicate entries
WITH Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission,
                Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number,
                Admission_Type, Discharge_Date, Medication, Test_Results
            ORDER BY Date_of_Admission
        ) AS flag
    FROM healthcare_dataset
)
DELETE h
FROM healthcare_dataset h 
JOIN Duplicates d 
    ON h.name = d.name
    AND h.age = d.age
    AND h.gender = d.gender
    AND h.blood_type = d.blood_type
    AND h.medical_condition = d.medical_condition
    AND h.date_of_admission = d.date_of_admission
    AND h.doctor = d.doctor
    AND h.hospital = d.hospital
    AND h.insurance_provider = d.insurance_provider
    AND h.billing_amount = d.billing_amount
    AND h.room_number = d.room_number
    AND h.admission_type = d.admission_type
    AND h.discharge_date = d.discharge_date
    AND h.medication = d.medication
    AND h.test_results = d.test_results
WHERE d.flag > 1;



-- 1.4 Verify duplicate removal
SELECT * 
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                name, age, gender, blood_type, medical_condition, date_of_admission,
                doctor, hospital, insurance_provider, billing_amount, room_number,
                admission_type, discharge_date, medication, test_results
            ORDER BY date_of_admission
        ) AS flag
    FROM healthcare_dataset
) t 
WHERE flag > 1;


-- =====================================================================
-- PART 2: HANDLE AGE VARIATION DATA ENTRY ERRORS
-- =====================================================================

-- 2.1 Investigate age variation anomalies
SELECT 
    name, 
    gender, 
    blood_type, 
    medical_condition, 
    date_of_admission, 
    doctor, 
    hospital, 
    insurance_provider, 
    billing_amount, 
    room_number, 
    admission_type, 
    discharge_date, 
    medication, 
    test_results, 
    COUNT(DISTINCT age) AS age_variations
FROM healthcare_dataset
GROUP BY 
    name, gender, blood_type, medical_condition, date_of_admission, 
    doctor, hospital, insurance_provider, billing_amount, room_number, 
    admission_type, discharge_date, medication, test_results
HAVING COUNT(DISTINCT age) > 1;


-- 2.2 Delete age duplicates, keeping only the youngest patient record
WITH Age_Duplicates AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                name, gender, blood_type, medical_condition, date_of_admission,
                doctor, hospital, insurance_provider, billing_amount, room_number,
                admission_type, discharge_date, medication, test_results 
            ORDER BY age
        ) AS flag 
    FROM healthcare_dataset
)

DELETE FROM Age_Duplicates
WHERE flag > 1;




-- =====================================================================
-- PART 3: CREATE UNIQUE IDENTIFIERS
-- =====================================================================

-- 3.1 Add patient_id column
ALTER TABLE healthcare_dataset
ADD patient_id INT;

-- 3.2 Assign patient IDs based on name, blood type, and age range (±6 years)
-- Note: This logic assumes patients with same name and blood type within 6 years age difference are same person
WITH PatientData AS (
    SELECT 
        name,
        blood_type,
        age,
        ROW_NUMBER() OVER (ORDER BY name, blood_type, age) AS row_num
    FROM healthcare_dataset
),
GroupedPatients AS (
    SELECT 
        p1.name,
        p1.blood_type,
        p1.age,
        MIN(p2.row_num) AS group_id
    FROM PatientData p1
    LEFT JOIN PatientData p2
        ON p1.name = p2.name
        AND p1.blood_type = p2.blood_type
        AND p2.age BETWEEN p1.age - 6 AND p1.age + 6 -- ±6 years range
    GROUP BY p1.name, p1.blood_type, p1.age
),
FinalPatients AS (
    SELECT 
        name,
        blood_type,
        age,
        DENSE_RANK() OVER (ORDER BY group_id) AS patient_id
    FROM GroupedPatients
)
UPDATE h 
SET h.patient_id = f.patient_id 
FROM healthcare_dataset h
LEFT JOIN FinalPatients f 
    ON h.name = f.name
    AND h.blood_type = f.blood_type
    AND h.age = f.age;


-- =====================================================================
-- PART 4: STANDARDIZE BILLING AMOUNTS
-- =====================================================================

-- 4.1 Update billing amount column to decimal with 2 decimal places
ALTER TABLE healthcare_dataset
ALTER COLUMN billing_amount DECIMAL(10,2);

UPDATE healthcare_dataset
SET billing_amount = CAST(billing_amount AS DECIMAL(10,2));


-- =====================================================================
-- PART 5: CREATE VISIT IDENTIFIERS
-- =====================================================================

-- 5.1 Add visit_id column
ALTER TABLE healthcare_dataset
ADD visit_id INT;

-- 5.2 Assign sequential visit IDs ordered by admission date
WITH VisitData AS (
    SELECT  
        name, 
        age, 
        blood_type, 
        date_of_admission,
        ROW_NUMBER() OVER (ORDER BY date_of_admission) AS visit_id
    FROM healthcare_dataset
)


UPDATE h
SET h.visit_id = v.visit_id
FROM healthcare_dataset h 
LEFT JOIN VisitData v 
    ON h.name = v.name
    AND h.age = v.age
    AND h.blood_type = v.blood_type
    AND h.date_of_admission = v.date_of_admission;




-- =====================================================================
-- PART 6: DATA ANALYSIS QUERIES
-- =====================================================================

-- 6.1 Hospital with most visits
SELECT TOP 1
    hospital,
    COUNT(visit_id) AS number_of_visits
FROM healthcare_dataset
GROUP BY hospital
ORDER BY number_of_visits DESC;


-- 6.2 Patients with most hospital visits
SELECT
    patient_id,
    name,
    COUNT(visit_id) AS hospital_visits
FROM healthcare_dataset
GROUP BY patient_id, name
ORDER BY hospital_visits DESC;


-- 6.3 All medical conditions treated
SELECT DISTINCT medical_condition
FROM healthcare_dataset;


-- 6.4 Highest single medical bill per patient
SELECT 
    patient_id,
    name,
    MAX(billing_amount) AS max_bill_amount
FROM healthcare_dataset
GROUP BY patient_id, name
ORDER BY max_bill_amount DESC;


-- 6.5 Smallest positive medical bill per patient
SELECT 
    patient_id,
    name,
    MIN(billing_amount) AS min_bill_amount
FROM healthcare_dataset
GROUP BY patient_id, name
HAVING MIN(billing_amount) > 0.00
ORDER BY min_bill_amount;


-- 6.6 Average medical bill
SELECT 
    ROUND(CAST(AVG(billing_amount) AS DECIMAL(10,2)), 2) AS average_bill_amount
FROM healthcare_dataset;


-- 6.7 Patients with same name as their doctor (potential fraud check)
SELECT *
FROM healthcare_dataset
WHERE name = doctor;


-- 6.8 Most frequent patient name
SELECT 
    name,
    COUNT(name) AS name_count
FROM healthcare_dataset
WHERE name = 'Michael Williams'
GROUP BY name;

-- 6.9 Doctors working at multiple hospitals
SELECT COUNT(*) AS doctor_count
FROM (
    SELECT 
        doctor,
        COUNT(DISTINCT hospital) AS distinct_hospital_count
    FROM healthcare_dataset
    GROUP BY doctor
    HAVING COUNT(DISTINCT hospital) > 1
) t;


-- 6.10 Top 10 doctors by patient visits
SELECT TOP 10
    doctor,
    COUNT(visit_id) AS number_of_patient_visits
FROM healthcare_dataset
GROUP BY doctor
ORDER BY number_of_patient_visits DESC;


-- 6.11 Frequency of each medical condition
SELECT 
    medical_condition,
    COUNT(medical_condition) AS number_of_instances
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY medical_condition;


-- 6.12 Yearly visit trends (2019-2024)
SELECT 
    YEAR(date_of_admission) AS year,
    COUNT(visit_id) AS visit_count
FROM healthcare_dataset
WHERE YEAR(date_of_admission) BETWEEN 2019 AND 2024
GROUP BY YEAR(date_of_admission)
ORDER BY year;


-- 6.13 Most prescribed medication for Asthma
SELECT TOP 1
    medical_condition,
    medication,
    COUNT(medication) AS prescription_count
FROM healthcare_dataset
WHERE medical_condition = 'Asthma'
GROUP BY medical_condition, medication
ORDER BY prescription_count DESC;


-- 6.14 Gender distribution
SELECT 
    gender,
    COUNT(patient_id) AS patient_count
FROM healthcare_dataset
GROUP BY gender;


-- 6.15 Admission type distribution
SELECT 
    admission_type,
    COUNT(patient_id) AS patient_count
FROM healthcare_dataset
GROUP BY admission_type;


-- 6.16 Emergency visits distribution
SELECT 
    admission_type,
    COUNT(patient_id) AS patient_count
FROM healthcare_dataset
WHERE admission_type = 'Emergency'
GROUP BY admission_type;


-- 6.17 Blood type distribution
SELECT 
    blood_type,
    COUNT(*) AS blood_type_count
FROM healthcare_dataset
GROUP BY blood_type;


-- 6.18 Insurance provider usage
SELECT 
    insurance_provider,
    COUNT(patient_id) AS provider_count
FROM healthcare_dataset
GROUP BY insurance_provider
ORDER BY provider_count DESC;


-- 6.19 Average billing by medical condition
SELECT
    medical_condition,
    CAST(ROUND(AVG(billing_amount), 2) AS DECIMAL(10,2)) AS average_bill
FROM healthcare_dataset
GROUP BY medical_condition;


-- 6.20 Top 10 hospitals by total billing
SELECT TOP 10
    hospital,
    SUM(billing_amount) AS bill_sum
FROM healthcare_dataset
GROUP BY hospital
ORDER BY bill_sum DESC;


-- 6.21 Average length of stay by medical condition
SELECT 
    medical_condition,
    AVG(DATEDIFF(DAY, date_of_admission, discharge_date)) AS average_length_of_stay_in_days
FROM healthcare_dataset
GROUP BY medical_condition;


-- 6.22 Monthly visit trends
SELECT 
    DATEFROMPARTS(YEAR(date_of_admission), MONTH(date_of_admission), 1) AS admission_month,
    COUNT(visit_id) AS visit_count
FROM healthcare_dataset
GROUP BY DATEFROMPARTS(YEAR(date_of_admission), MONTH(date_of_admission), 1)
ORDER BY admission_month;


-- 6.23 Patients with highest total billing
SELECT 
    name,
    patient_id,
    SUM(billing_amount) AS total_billing_amount
FROM healthcare_dataset
GROUP BY name, patient_id
ORDER BY total_billing_amount DESC;


-- 6.24 Doctors treating most diverse conditions
SELECT TOP 10 
    doctor,
    COUNT(DISTINCT medical_condition) AS unique_conditions_treated
FROM healthcare_dataset
GROUP BY doctor
ORDER BY unique_conditions_treated DESC;


-- 6.25 Patients with multiple medical conditions
SELECT 
    name,
    COUNT(DISTINCT medical_condition) AS unique_conditions_treated
FROM healthcare_dataset
GROUP BY name
HAVING COUNT(DISTINCT medical_condition) > 1
ORDER BY unique_conditions_treated DESC;


-- 6.26 Most common conditions among patients with exactly 6 different conditions
SELECT 
    medical_condition, 
    COUNT(*) AS condition_count
FROM healthcare_dataset
WHERE name IN (
    SELECT name
    FROM healthcare_dataset
    GROUP BY name
    HAVING COUNT(DISTINCT medical_condition) = 6
)
GROUP BY medical_condition
ORDER BY condition_count DESC;


-- 6.27 Most common conditions among patients with exactly 5 different conditions
SELECT 
    medical_condition,
    COUNT(*) AS condition_count
FROM healthcare_dataset
WHERE name IN (
    SELECT name
    FROM healthcare_dataset
    GROUP BY name 
    HAVING COUNT(DISTINCT medical_condition) = 5
)
GROUP BY medical_condition
ORDER BY condition_count DESC;


-- 6.28 Detect 30-day readmissions
WITH Admissions AS (
    SELECT 
        name, 
        date_of_admission,
        LEAD(date_of_admission) OVER (PARTITION BY name ORDER BY date_of_admission) AS next_admission
    FROM healthcare_dataset
)
SELECT 
    name,
    COUNT(*) AS readmission_count
FROM Admissions
WHERE DATEDIFF(DAY, date_of_admission, next_admission) <= 30
GROUP BY name
ORDER BY readmission_count DESC;


-- 6.29 Correlation between age and billing amount
SELECT 
    age,
    CAST(AVG(billing_amount) AS DECIMAL(10,2)) AS average_bill
FROM healthcare_dataset
GROUP BY age
ORDER BY age;
