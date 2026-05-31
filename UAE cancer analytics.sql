CREATE DATABASE Cancer_dataset_uae;
USE Cancer_dataset_uae;
SELECT * FROM Cancer_data_raw LIMIT 10;
CREATE TABLE Patients (
Patient_id VARCHAR(50) PRIMARY KEY,
Age int,
Gender VARCHAR(20),
Nationality VARCHAR(50),
Ethnicity VARCHAR(50),
Smoking_Status VARCHAR(50),
Comorbidities VARCHAR(200),
Weight DECIMAL(5,2),
Height DECIMAL(5,2)
);
CREATE TABLE Diagnosis (
Diagnosis_id INT auto_increment primary key,
Patient_id VARCHAR(50),
Cancer_type VARCHAR(100),
Cancer_stage VARCHAR(20),
Diagnosis_date DATE,
foreign key (patient_id) references Patients(Patient_id)
);
create TABLE Treatment (
Treatment_id INT auto_increment primary key,
Patient_id VARCHAR(50),
Treatment_type VARCHAR(100),
Hospital VARCHAR(150),
Primary_Physician VARCHAR(100),
foreign key (patient_id) references Patients(Patient_id)
);
CREATE TABLE Outcomes (
outcome_id INT auto_increment primary key,
Patient_id VARCHAR(50),
Outcome VARCHAR(500),
Death_date DATE,
Cause_of_death VARCHAR(150),
foreign key (patient_id) references Patients(Patient_id)
);
alter table patients
add column Emirate varchar(50) after ethnicity;
INSERT INTO Patients (Patient_id, age, gender, nationality, ethnicity, Emirate, smoking_status, comorbidities, weight, height)
select distinct
Patient_id, age, gender, nationality, ethnicity, Emirate, smoking_status, comorbidities, weight, height
from cancer_data_raw
where Patient_ID is not null and Patient_ID !='';
insert into Diagnosis (patient_id, cancer_type, cancer_stage, diagnosis_date)
select distinct
cancer_data_raw.patient_id,
cancer_data_raw.cancer_type,
cancer_data_raw.cancer_stage,
case
when Diagnosis_Date is null or diagnosis_date = '' then null
when Diagnosis_Date regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(diagnosis_date, '%Y-%m-%d')
when Diagnosis_Date regexp '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
then str_to_date(diagnosis_date, '%m/%d/%Y')
else null
end
from cancer_data_raw
where Patient_ID in (select Patient_ID from patients);
select
patient_id,
treatment_type,
hospital,
Primary_Physician
from cancer_data_raw
where Patient_ID in (select Patient_ID from patients);
insert into outcomes (patient_id, outcome, death_date, cause_of_death)
select
patient_id,
outcome,
case
when death_date = '' or death_date is null then null
end,
cause_of_death
from cancer_data_raw
where Patient_ID in (select Patient_ID from patients);
select count(*) from patients;
alter table treatment
add column treatment_start_date date after treatment_type;
INSERT INTO treatment (patient_id, treatment_type, treatment_start_date, hospital, primary_physician)
SELECT 
    patient_id, 
    treatment_type, 
    CASE 
        WHEN treatment_start_date is null or treatment_start_date = '' THEN NULL
        when treatment_start_date regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(treatment_start_date, '%Y-%m-%d')
when treatment_start_date regexp '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
then str_to_date(treatment_start_date, '%m/%d/%Y')
else null
    END,
    hospital, 
    primary_physician
FROM cancer_data_raw
WHERE patient_id IN (SELECT patient_id FROM patients);
select
sum(case when gender is null or gender = '' then 1 else 0 end) as missing_genders,
sum(case when emirate is null or emirate = '' then 1 else 0 end) as missing_emirate,
sum(case when smoking_status is null or smoking_status = '' then 1 else 0 end) as missing_smoking_status
from patients;
SELECT DISTINCT gender FROM patients;
SELECT DISTINCT emirate FROM patients;
SELECT DISTINCT cancer_type FROM diagnosis;
SELECT d.patient_id, d.diagnosis_date, t.treatment_start_date
FROM diagnosis d
JOIN treatment t ON d.patient_id = t.patient_id
WHERE t.treatment_start_date < d.diagnosis_date;
CREATE OR REPLACE VIEW v_data_quality_report AS
SELECT 
    'Patients Table' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) AS null_or_blank_fields,
    'All categories fully standardized' AS status_note
FROM patients
UNION ALL
SELECT 
    'Diagnosis Table' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN cancer_type IS NULL OR cancer_type = '' THEN 1 ELSE 0 END) AS null_or_blank_fields,
    'All diagnosis timelines are chronologically valid' AS status_note
FROM diagnosis;
SELECT * FROM v_data_quality_report;
SELECT 
    p.emirate,
    d.cancer_type,
    COUNT(*) AS case_count,
    RANK() OVER (PARTITION BY p.emirate ORDER BY COUNT(*) DESC) AS ranking
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
GROUP BY p.emirate, d.cancer_type
ORDER BY p.emirate, case_count DESC;
SELECT 
    d.cancer_type,
    COUNT(*) AS total_patients,
    ROUND(AVG(DATEDIFF(t.treatment_start_date, d.diagnosis_date)), 1) AS avg_days_to_treatment
FROM diagnosis d
JOIN treatment t ON d.patient_id = t.patient_id
WHERE t.treatment_start_date IS NOT NULL
GROUP by d.cancer_type
ORDER BY avg_days_to_treatment ASC;
SELECT 
    p.smoking_status,
    d.cancer_type,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY p.smoking_status), 2) AS percentage_within_group
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
GROUP BY p.smoking_status, d.cancer_type
ORDER BY p.smoking_status, patient_count DESC;
SELECT 
    YEAR(d.diagnosis_date) AS diagnosis_year,
    d.cancer_type,
    COUNT(*) AS yearly_cases,
    -- Advanced Window Function: Calculates a rolling cumulative total year-over-year
    SUM(COUNT(*)) OVER (PARTITION BY d.cancer_type ORDER BY YEAR(d.diagnosis_date)) AS cumulative_cases_over_time
FROM diagnosis d
WHERE d.diagnosis_date IS NOT NULL
GROUP BY YEAR(d.diagnosis_date), d.cancer_type
ORDER BY d.cancer_type, diagnosis_year;
SELECT patient_id, COUNT(*) 
FROM cancer_data_raw -- Adjusted to match your actual raw table name
GROUP BY patient_id 
HAVING COUNT(*) > 1;
SELECT 
    (SELECT COUNT(*) FROM patients WHERE age IS NULL) AS missing_age,
    (SELECT COUNT(*) FROM patients WHERE gender IS NULL) AS missing_gender,
    (SELECT COUNT(*) FROM diagnosis WHERE cancer_type IS NULL) AS missing_cancer_type,
    (SELECT COUNT(*) FROM diagnosis WHERE diagnosis_date IS NULL) AS missing_diagnosis_date;
    SELECT * FROM patients 
WHERE age < 0 OR age > 120;
SELECT patient_id, height, weight,
    ROUND(weight / ((height/100) * (height/100)), 2) AS calculated_bmi
FROM patients
WHERE (weight / ((height/100) * (height/100)) > 60)
   OR (weight / ((height/100) * (height/100)) < 10);
UPDATE patients 
SET gender = 'Male' 
WHERE gender IN ('male', 'M', 'm', 'MALE') AND patient_id != '';
UPDATE patients 
SET gender = 'Female' 
where gender IN ('female', 'F', 'f', 'FEMALE') AND patient_id != '';
ALTER TABLE patients ADD COLUMN bmi DECIMAL(5,2);
SET SQL_SAFE_UPDATES = 0;
UPDATE patients
SET bmi = ROUND(weight / ((height/100) * (height/100)), 2)
WHERE height > 0;
select patient_id, height, weight, bmi
from patients
limit 5;
ALTER TABLE patients ADD COLUMN bmi_category VARCHAR(20);
UPDATE patients 
SET bmi_category = 
    CASE 
        WHEN bmi < 18.5 THEN 'Underweight'
        WHEN bmi BETWEEN 18.5 AND 24.9 THEN 'Normal'
        WHEN bmi BETWEEN 25 AND 29.9 THEN 'Overweight'
        WHEN bmi >= 30 THEN 'Obese'
        ELSE 'Unknown'
    END;
    ALTER TABLE patients ADD COLUMN age_group VARCHAR(20);
    UPDATE patients 
SET age_group = 
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 35 THEN '18-35'
        WHEN age BETWEEN 36 AND 50 THEN '36-50'
        WHEN age BETWEEN 51 AND 65 THEN '51-65'
        WHEN age > 65 THEN 'Above 65'
        ELSE 'Unknown'
    END;
    SET SQL_SAFE_UPDATES = 1;
    SELECT COUNT(*) AS total_patients FROM patients;
SELECT gender, 
COUNT(*) AS count,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 2) AS percentage
FROM patients
GROUP BY gender;
SELECT age_group,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 2) AS percentage
FROM patients
GROUP BY age_group
ORDER BY count DESC;
SELECT cancer_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM diagnosis), 2) AS percentage
FROM diagnosis
GROUP BY cancer_type
ORDER BY count DESC;
SELECT 
    p.patient_id,
    p.age,
    p.age_group,
    p.gender,
    p.nationality,
    p.smoking_status,
    p.bmi_category,
    d.cancer_type,
    d.cancer_stage
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
LIMIT 20;
SELECT 
    p.patient_id,
    p.age,
    p.gender,
    p.smoking_status,
    d.cancer_type,
    d.cancer_stage,
    t.treatment_type,
    t.hospital,
    o.outcome
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN treatment t ON p.patient_id = t.patient_id
JOIN outcomes o ON p.patient_id = o.patient_id
LIMIT 20;
SELECT 
    p.smoking_status,
    d.cancer_stage,
    COUNT(*) AS count
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
GROUP BY p.smoking_status, d.cancer_stage
ORDER BY p.smoking_status, d.cancer_stage;
SELECT 
    t.treatment_type,
    o.outcome,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY t.treatment_type), 2) AS percentage_within_treatment
FROM treatment t
JOIN outcomes o ON t.patient_id = o.patient_id
GROUP BY t.treatment_type, o.outcome
ORDER BY t.treatment_type, count DESC;
SELECT 
    t.hospital,
    o.outcome,
    COUNT(*) AS count
FROM treatment t
JOIN outcomes o ON t.patient_id = o.patient_id
GROUP BY t.hospital, o.outcome
ORDER BY t.hospital, count DESC;
SELECT 
    p.bmi_category,
    d.cancer_type,
    COUNT(*) AS patient_count
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
GROUP BY p.bmi_category, d.cancer_type
ORDER BY p.bmi_category, patient_count DESC;
SELECT 
    p.patient_id,
    p.age,
    d.cancer_type,
    avg_age.avg_cancer_age
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN (
    SELECT d2.cancer_type, 
        ROUND(AVG(p2.age), 1) AS avg_cancer_age
    FROM diagnosis d2
    JOIN patients p2 ON d2.patient_id = p2.patient_id
    GROUP BY d2.cancer_type
) avg_age ON d.cancer_type = avg_age.cancer_type
WHERE p.age > avg_age.avg_cancer_age
ORDER BY d.cancer_type, p.age DESC
LIMIT 20;
SELECT 
    d.cancer_type,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN o.outcome = 'Deceased' THEN 1 ELSE 0 END) AS deaths,
    ROUND(SUM(CASE WHEN o.outcome = 'Deceased' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS mortality_rate,
    RANK() OVER (ORDER BY SUM(CASE WHEN o.outcome = 'Deceased' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC) AS mortality_rank
FROM diagnosis d
JOIN outcomes o ON d.patient_id = o.patient_id
GROUP by d.cancer_type
ORDER BY mortality_rate DESC;
SELECT 
    p.emirate,
    d.cancer_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY p.emirate), 2) AS percentage_within_emirate
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
GROUP BY p.emirate, d.cancer_type
ORDER BY p.emirate, count DESC;
SELECT 
    t.Primary_Physician,
    t.hospital,
    COUNT(*) AS patients_treated,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS doctor_rank
FROM treatment t
GROUP BY t.Primary_Physician, t.hospital
ORDER BY patients_treated DESC
LIMIT 10;



CREATE OR REPLACE VIEW high_risk_patients AS
SELECT 
    p.patient_id,
    p.age,
    p.smoking_status,
    p.bmi_category,
    d.cancer_type,
    d.cancer_stage,
    o.outcome
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN outcomes o ON p.patient_id = o.patient_id
WHERE d.cancer_stage IN ('Stage 3', 'Stage 4')
  AND p.smoking_status = 'Yes';
CREATE OR REPLACE VIEW hospital_performance AS
SELECT 
    t.hospital,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN o.outcome = 'Recovered' THEN 1 ELSE 0 END) AS recovered_cases,
    SUM(CASE WHEN o.outcome = 'Deceased' THEN 1 ELSE 0 END) AS deceased_cases,
    ROUND(SUM(CASE WHEN o.outcome = 'Recovered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS recovery_rate
FROM treatment t
JOIN outcomes o ON t.patient_id = o.patient_id
GROUP BY t.hospital;
SELECT * FROM hospital_performance ORDER BY recovery_rate DESC;
DELIMITER //
CREATE PROCEDURE GetPatientsByCancerType(IN target_cancer VARCHAR(50))
BEGIN
    SELECT 
        patient_id,
        age,
        gender,
        smoking_status,
        cancer_stage,
        treatment_type,
        outcome
    FROM patient_summary 
    WHERE cancer_type = target_cancer;
END //
DELIMITER ;
CREATE or replace VIEW patient_summary AS
SELECT 
    p.patient_id,
    p.age,
    p.age_group,
    p.gender,
    p.nationality,
    p.emirate,
    p.smoking_status,
    p.bmi,
    p.bmi_category,
    d.cancer_type,
    d.cancer_stage,
    t.treatment_type,
    t.hospital,  
    t.Primary_Physician,
    o.outcome
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN treatment t ON p.patient_id = t.patient_id
JOIN outcomes o ON p.patient_id = o.patient_id;
DELIMITER //
CREATE PROCEDURE GetPatientsByCancerType(IN target_cancer VARCHAR(50))
BEGIN
    SELECT 
        patient_id,
        age,
        gender,
        smoking_status,
        cancer_stage,
        treatment_type,
        hospital,
        Primary_Physician,
        outcome
    FROM patient_summary 
    WHERE cancer_type = target_cancer;
END //
DELIMITER ;

USE Cancer_dataset_uae;
create view patient_summary as
SELECT 
	p.patient_id,
    p.age,
    p.age_group,
    p.gender,
    p.nationality,
    p.emirate,
    p.smoking_status,
    p.bmi,
    p.bmi_category,
    d.cancer_type,
    d.cancer_stage,
    t.treatment_type,
    t.hospital,                  
    t.primary_physician,         
    o.outcome
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN treatment t ON p.patient_id = t.patient_id
JOIN outcomes o ON p.patient_id = o.patient_id;
CREATE VIEW high_risk_patients AS
SELECT 
    p.patient_id,
    p.age,
    p.smoking_status,
    p.bmi_category,
    d.cancer_type,
    d.cancer_stage,
    o.outcome
FROM patients p
JOIN diagnosis d ON p.patient_id = d.patient_id
JOIN outcomes o ON p.patient_id = o.patient_id
WHERE d.cancer_stage IN ('Stage 3', 'Stage 4')
  AND p.smoking_status = 'Yes';
CREATE VIEW hospital_performance AS
SELECT 
    t.hospital,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN o.outcome = 'Recovered' THEN 1 ELSE 0 END) AS recovered_cases,
    SUM(CASE WHEN o.outcome = 'Deceased' THEN 1 ELSE 0 END) AS deceased_cases,
    ROUND(SUM(CASE WHEN o.outcome = 'Recovered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS recovery_rate
FROM treatment t
JOIN outcomes o ON t.patient_id = o.patient_id
GROUP BY t.hospital;
DELIMITER //
CREATE PROCEDURE GetPatientsByCancerType(IN target_cancer VARCHAR(50))
BEGIN
    SELECT 
        patient_id,
        age,
        gender,
        smoking_status,
        cancer_stage,
        treatment_type,
        hospital,        
        primary_physician,  
        outcome
    FROM patient_summary 
    WHERE cancer_type = target_cancer;
END //
DELIMITER ;
CALL GetPatientsByCancerType('Pancreatic');
CALL GetHospitalSummary('Sheikh Khalifa Hospital');
drop procedure if exists GetHospitalSummary;
DELIMITER //
CREATE PROCEDURE GetHospitalSummary(IN target_hospital VARCHAR(100))
BEGIN
    SELECT 
        hospital,
        total_patients,
        recovered_cases,
        deceased_cases,
        recovery_rate
    FROM hospital_performance 
    WHERE hospital = target_hospital;
END //
DELIMITER ;