# Healthcare Data Cleansing & Analysis Project
SQL Project + Health Care Data + From Raw Data to Business Insights

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
*  Age Variation Correction: Resolved data entry errors where same patient had different ages, keeping youngest record
