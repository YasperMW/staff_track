-- SQL Script to create simplified departments and designations tables
-- This script will:
-- 1. Drop existing tables and constraints
-- 2. Create departments table without designations column
-- 3. Create designations table with department_id foreign key
-- 4. Insert US hospital departments and their designations

-- ============================================
-- 1. Drop existing tables and constraints
-- ============================================

-- Drop junction tables first (due to foreign key constraints)
DROP TABLE IF EXISTS department_designations CASCADE;

-- Drop designations table
DROP TABLE IF EXISTS designations CASCADE;

-- Drop departments table
DROP TABLE IF EXISTS departments CASCADE;

-- ============================================
-- 2. Create departments table (without designations column)
-- ============================================

CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES users(user_id)
);

-- ============================================
-- 3. Create designations table (with department_id foreign key)
-- ============================================

CREATE TABLE designations (
    designation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES users(user_id),
    UNIQUE(department_id, name) -- Each department can have unique designation names
);

-- ============================================
-- 4. Create indexes for performance
-- ============================================

CREATE INDEX idx_departments_name ON departments(name);
CREATE INDEX idx_designations_department_id ON designations(department_id);
CREATE INDEX idx_designations_name ON designations(name);

-- ============================================
-- 5. Insert  Hospital Departments
-- ============================================

-- Emergency Department
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Emergency Department', 'Provides immediate medical care for acute illnesses and injuries', NOW(), NOW());

-- Intensive Care Unit (ICU)
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Intensive Care Unit (ICU)', 'Provides critical care for seriously ill patients', NOW(), NOW());

-- Operating Room (OR)
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Operating Room (OR)', 'Surgical procedures and operations', NOW(), NOW());

-- Medical-Surgical Unit
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Medical-Surgical Unit', 'General medical and surgical patient care', NOW(), NOW());

-- Obstetrics and Gynecology (OB/GYN)
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Obstetrics and Gynecology (OB/GYN)', 'Women''s health and childbirth services', NOW(), NOW());

-- Pediatrics
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Pediatrics', 'Medical care for infants, children, and adolescents', NOW(), NOW());

-- Radiology
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Radiology', 'Medical imaging and diagnostic services', NOW(), NOW());

-- Laboratory
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Laboratory', 'Clinical laboratory testing and analysis', NOW(), NOW());

-- Pharmacy
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Pharmacy', 'Medication dispensing and pharmaceutical care', NOW(), NOW());

-- Physical Therapy
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Physical Therapy', 'Rehabilitation and physical therapy services', NOW(), NOW());

-- Administration
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Administration', 'Hospital management and administrative services', NOW(), NOW());

-- Finance
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Finance', 'Financial management and accounting services', NOW(), NOW());

-- Human Resources
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Human Resources', 'Employee management and HR services', NOW(), NOW());

-- Information Technology (IT)
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Information Technology (IT)', 'Technology infrastructure and IT support', NOW(), NOW());

-- Marketing and Communications
INSERT INTO departments (name, description, created_at, updated_at) VALUES
('Marketing and Communications', 'Hospital marketing and public relations', NOW(), NOW());

-- ============================================
-- 6. Insert Designations for each department
-- ============================================

-- Emergency Department designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Emergency Physician', 'Physician specializing in emergency medicine', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Emergency Nurse', 'Nurse specializing in emergency care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Paramedic', 'Emergency medical services provider', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'ER Technician', 'Emergency room technician', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Triage Nurse', 'Nurse responsible for patient assessment and prioritization', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Emergency Medical Director', 'Director of emergency medical services', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Trauma Surgeon', 'Surgeon specializing in trauma care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Emergency Department Manager', 'Manager of emergency department operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Emergency Department';

-- ICU designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'ICU Physician', 'Physician specializing in critical care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Critical Care Nurse', 'Nurse specializing in intensive care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Respiratory Therapist', 'Therapist specializing in respiratory care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'ICU Manager', 'Manager of intensive care unit', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Critical Care Specialist', 'Specialist in critical care medicine', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'ICU Technician', 'Technician supporting ICU operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pulmonologist', 'Physician specializing in lung diseases', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Intensivist', 'Physician specializing in intensive care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Intensive Care Unit (ICU)';

-- OR designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Surgeon', 'Physician who performs surgical procedures', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Anesthesiologist', 'Physician specializing in anesthesia', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'OR Nurse', 'Nurse assisting in surgical procedures', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Surgical Technician', 'Technician assisting surgeons', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'OR Manager', 'Manager of operating room operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Perioperative Nurse', 'Nurse specializing in perioperative care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Surgical Assistant', 'Assistant to surgical team', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Circulating Nurse', 'Nurse managing operating room flow', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Operating Room (OR)';

-- Medical-Surgical designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Staff Nurse', 'Registered nurse providing general patient care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Charge Nurse', 'Nurse responsible for unit management', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Medical-Surgical Nurse', 'Nurse specializing in medical-surgical care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Unit Manager', 'Manager of medical-surgical unit', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Patient Care Technician', 'Technician assisting with patient care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Medication Nurse', 'Nurse responsible for medication administration', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Wound Care Nurse', 'Nurse specializing in wound management', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Case Manager', 'Professional managing patient care coordination', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Medical-Surgical Unit';

-- OB/GYN designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'OB/GYN Physician', 'Physician specializing in women''s health', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Labor and Delivery Nurse', 'Nurse specializing in childbirth care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Midwife', 'Healthcare professional specializing in childbirth', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Neonatal Nurse', 'Nurse specializing in newborn care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'OB Technician', 'Technician assisting in obstetric procedures', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Lactation Consultant', 'Specialist in breastfeeding support', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Gynecological Nurse', 'Nurse specializing in gynecological care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Women''s Health Nurse Practitioner', 'Nurse practitioner specializing in women''s health', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Obstetrics and Gynecology (OB/GYN)';

-- Pediatrics designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatrician', 'Physician specializing in child healthcare', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatric Nurse', 'Nurse specializing in pediatric care', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Child Life Specialist', 'Specialist supporting children in healthcare', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatric Nurse Practitioner', 'Nurse practitioner specializing in pediatrics', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatric Resident', 'Physician in pediatric training', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatric Medical Assistant', 'Medical assistant specializing in pediatrics', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Developmental Pediatrician', 'Physician specializing in child development', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pediatric Surgeon', 'Surgeon specializing in pediatric surgery', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pediatrics';

-- Radiology designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Radiologist', 'Physician specializing in medical imaging', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Radiology Technician', 'Technician operating medical imaging equipment', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'X-Ray Technician', 'Technician operating X-ray equipment', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'MRI Technician', 'Technician operating MRI equipment', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'CT Technician', 'Technician operating CT scanner', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Ultrasound Technician', 'Technician operating ultrasound equipment', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Interventional Radiologist', 'Radiologist performing interventional procedures', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Radiology Manager', 'Manager of radiology department', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Radiology';

-- Laboratory designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Medical Laboratory Scientist', 'Professional performing laboratory tests', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Lab Technician', 'Technician assisting in laboratory operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Phlebotomist', 'Professional who draws blood for testing', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Lab Manager', 'Manager of laboratory operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Clinical Pathologist', 'Physician specializing in laboratory medicine', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Medical Technologist', 'Technologist performing complex lab tests', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Cytotechnologist', 'Technologist studying cells for disease', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Histology Technician', 'Technician preparing tissue samples', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Laboratory';

-- Pharmacy designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pharmacist', 'Professional dispensing medications', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pharmacy Technician', 'Technician assisting pharmacists', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Clinical Pharmacist', 'Pharmacist working with clinical teams', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pharmacy Manager', 'Manager of pharmacy operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Compounding Pharmacist', 'Pharmacist preparing customized medications', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Oncology Pharmacist', 'Pharmacist specializing in cancer medications', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Pharmacy Buyer', 'Professional purchasing medications', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Informatics Pharmacist', 'Pharmacist specializing in pharmacy informatics', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Pharmacy';

-- Physical Therapy designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Physical Therapist', 'Therapist providing rehabilitation services', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Physical Therapy Assistant', 'Assistant to physical therapist', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Rehabilitation Manager', 'Manager of rehabilitation services', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Sports Medicine Specialist', 'Specialist in sports-related injuries', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Occupational Therapist', 'Therapist helping with daily living skills', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Therapy Technician', 'Technician assisting therapists', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Rehabilitation Aide', 'Aide assisting in rehabilitation', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Hand Therapist', 'Therapist specializing in hand rehabilitation', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Physical Therapy';

-- Administration designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Hospital Administrator', 'Senior hospital management position', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Chief Executive Officer', 'CEO of the hospital', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Chief Operating Officer', 'COO of the hospital', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Administrative Director', 'Director of administrative services', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Department Head', 'Head of a specific department', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Administrative Assistant', 'Assistant providing administrative support', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Executive Assistant', 'Assistant to senior executives', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Hospital Manager', 'Manager of hospital operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Administration';

-- Finance designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Chief Financial Officer', 'CFO of the hospital', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Accountant', 'Professional managing financial records', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Financial Analyst', 'Professional analyzing financial data', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Billing Specialist', 'Specialist handling medical billing', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Revenue Cycle Manager', 'Manager of revenue cycle operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Accounts Payable Clerk', 'Clerk managing accounts payable', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Payroll Manager', 'Manager of payroll operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Financial Controller', 'Controller of financial operations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Finance';

-- HR designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'HR Director', 'Director of human resources', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'HR Manager', 'Manager of human resources department', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'HR Generalist', 'Generalist providing HR support', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Recruiter', 'Professional responsible for hiring', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Training Coordinator', 'Coordinator of employee training', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Compensation Analyst', 'Analyst managing compensation programs', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Employee Relations Specialist', 'Specialist handling employee relations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'HR Assistant', 'Assistant providing HR support', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Human Resources';

-- IT designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'IT Director', 'Director of information technology', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'System Administrator', 'Professional managing IT systems', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Network Administrator', 'Professional managing network infrastructure', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Database Administrator', 'Professional managing databases', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'IT Support Specialist', 'Professional providing IT support', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Software Developer', 'Developer creating software solutions', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Security Analyst', 'Analyst managing IT security', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'IT Project Manager', 'Manager of IT projects', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Information Technology (IT)';

-- Marketing designations
INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Marketing Director', 'Director of marketing activities', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Communications Manager', 'Manager of communications activities', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Public Relations Specialist', 'Specialist handling public relations', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Marketing Coordinator', 'Coordinator of marketing activities', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Content Creator', 'Creator of marketing content', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Social Media Manager', 'Manager of social media presence', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Graphic Designer', 'Designer creating visual content', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

INSERT INTO designations (name, description, department_id, created_at, updated_at)
SELECT 'Community Outreach Coordinator', 'Coordinator of community outreach', d.department_id, NOW(), NOW()
FROM departments d WHERE d.name = 'Marketing and Communications';

-- ============================================
-- Summary
-- ============================================

/*
Simplified Database Structure:

1. Departments Table:
   - department_id (UUID, Primary Key)
   - name (VARCHAR, Unique)
   - description (TEXT)
   - created_at, updated_at, deleted_at, deleted_by

2. Designations Table:
   - designation_id (UUID, Primary Key)
   - name (VARCHAR)
   - description (TEXT)
   - department_id (UUID, Foreign Key to departments)
   - created_at, updated_at, deleted_at, deleted_by
   - UNIQUE constraint on (department_id, name)

US Hospital Departments Created:
1. Emergency Department - 8 designations
2. Intensive Care Unit (ICU) - 8 designations
3. Operating Room (OR) - 8 designations
4. Medical-Surgical Unit - 8 designations
5. Obstetrics and Gynecology (OB/GYN) - 8 designations
6. Pediatrics - 8 designations
7. Radiology - 8 designations
8. Laboratory - 8 designations
9. Pharmacy - 8 designations
10. Physical Therapy - 8 designations
11. Administration - 8 designations
12. Finance - 8 designations
13. Human Resources - 8 designations
14. Information Technology (IT) - 8 designations
15. Marketing and Communications - 8 designations

Total: 15 departments with 120 designations

Features:
- Clean relational design
- Each designation belongs to exactly one department
- Proper foreign key constraints
- Unique designation names within each department
- Audit trail with timestamps
- Soft delete support
- Performance indexes
*/
