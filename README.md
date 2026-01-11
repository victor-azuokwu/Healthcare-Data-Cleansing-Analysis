# Healthcare Data Cleansing & Analysis Project
SQL Project + Health Care Data + From Raw Data to Business Insights

Table of Contents
Project Overview
Tools and Technologies
Dataset Overview
Data Cleaning and Feature Engineering
Exploratory Analysis
Key Insight and Findings 
Recommendations


### Project Overview
A comprehensive SQL solution for cleaning, standardizing, and analyzing healthcare data. This project transforms messy patient admission records through data cleansing, duplicate removal, ID assignment, and delivers key insights on hospital operations, patient trends, and financial metrics. 
Demonstrates end-to-end data processing from raw data to actionable analytics.

### Tools and Technologies
* SQL (Transact-SQL )
* Microsoft SQL Server for SQL Querying

### Dataset Overview
Columns: Name, Age, Gender, Blood Type, Medical Condition,	Date of Admission, Doctor,	Hospital, Insurance Provider,	Billing Amount, Room Number, Admission Type, Discharge Date, Medication, Test Results

Sample Preview

|Name	|Age |Gender|	Blood Type | Medical Condition | Date of Admission | Doctor |	Hospital |	Insurance Provider |	Billing Amount |	Room Number |	Admission Type |	Discharge Date |	Medication |	Test Results|
|-----|----|------|------------|-------------------| ------------------|--------|----------|---------------------|-----------------|--------------|----------------|-----------------|-------------|--------------|
|Bobby JacksOn|	30	|Male|	B-|	Cancer	|1/31/2024 |	Matthew Smith|	Sons and Miller|	Blue Cross|	18856.28131 |	328 |	Urgent |	2/2/2024|	Paracetamol |	Normal|
|LesLie TErRy|	62 |	Male |	A+ |	Obesity |	8/20/2019	| Samantha Davies |	Kim Inc	| Medicare |	33643.32729 |	265 |	Emergency |	8/26/2019 |	Ibuprofen |	Inconclusive |

### Data Cleaning and Feature Engineering

#### Phase 1: Data Standardization
* Name Formatting: Converted all patient names to Proper Case format using string manipulation
* Billing Normalization: Standardized billing amounts to 2 decimal places with DECIMAL(10,2) type

#### Phase 2: Duplicate Management
* Exact Duplicate Removal: Identified and deleted records with identical values across all medical columns
* Age Variation Correction: Resolved data entry errors where same patient had different ages, keeping youngest record

### Phase 3: Entity Resolution
* Patient ID Creation: Generated unique patient_id based on name, blood type, and age range (±6 years)
* Visit ID Assignment: Created sequential visit_id ordered by admission date for each patient encounter

### Phase 4: Data Validation
* Quality Verification: Confirmed successful duplicate removal with multiple validation queries
* Anomaly Detection: Identified edge cases like patients sharing names with doctors for fraud investigation

### Phase 5: Derived Features
* Readmission Flagging: Calculated 30-day readmissions using LEAD() window function
* Length of Stay: Computed hospital stay duration with DATEDIFF() between admission and discharge dates
* Monthly Aggregation: Created time-based features using DATEFROMPARTS() for trend analysis
  
### Phase 6: Data Integrity
* Positive Billing Filter: Isolated billing amounts > $0.00 to exclude accounting errors/overpayments
* Temporal Bounds: Applied date range filters (2019-2024) for consistent analysis periods
* Condition Counting: Calculated distinct medical conditions per patient for complexity analysis

### Exploratory Analysis
1. Most visited hospital
```SQL
SELECT TOP 1
    hospital,
    COUNT(visit_id) AS number_of_visits
FROM healthcare_dataset
GROUP BY hospital
ORDER BY number_of_visits DESC;
```
2. Detect 30-day readmissions rates
```SQL
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
```
3. Patients with highest total billing
```SQL
SELECT 
    name,
    patient_id,
    SUM(billing_amount) AS total_billing_amount
FROM healthcare_dataset
GROUP BY name, patient_id
ORDER BY total_billing_amount DESC;
```
4. Highest single medical bill per patient
```SQL
SELECT 
    patient_id,
    name,
    MAX(billing_amount) AS max_bill_amount
FROM healthcare_dataset
GROUP BY patient_id, name
ORDER BY max_bill_amount DESC;
```
5. Most common medical conditions
``` SQL
SELECT 
    medical_condition,
    COUNT(medical_condition) AS number_of_instances
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY medical_condition;
```
6. Top 10 doctors by patient visits
``` SQL
SELECT TOP 10
    doctor,
    COUNT(visit_id) AS number_of_patient_visits
FROM healthcare_dataset
GROUP BY doctor
ORDER BY number_of_patient_visits DESC;
```
### Key Insight and Findings 

###  Recommendations

Data Source [Download Here](https://www.kaggle.com/datasets/prasad22/healthcare-dataset/data)
   
