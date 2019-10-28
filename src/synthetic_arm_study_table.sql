-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)
-- Script to create & populate the study table: AMDSyntheticEyleaMeta having run synthetic_arm_large_tables.sql

-- create table to be used for this study only
DROP TABLE IF EXISTS AMDSyntheticEyleaArmMeta;

CREATE TABLE AMDSyntheticEyleaArmMeta
  SELECT PatientID, Eye, SiteID, Gender
  FROM PatientMeta 
  WHERE (PatientID, SiteID, Eye) IN (SELECT PatientID, SiteID, EyeCode FROM nvAMDSurgeryIndications);

CREATE INDEX idx_AMDSyntheticEyleaArmMeta_pt_st_e ON AMDSyntheticEyleaArmMeta (`PatientID`, `SiteID`, `Eye`);
CREATE INDEX idx_AMDSyntheticEyleaArmMeta_pt_st ON AMDSyntheticEyleaArmMeta (`PatientID`, `SiteID`);

-- extend table with columns we will later populate
ALTER TABLE AMDSyntheticEyleaArmMeta
  ADD COLUMN AgeAtBaseline INT(11) DEFAULT NULL,
  ADD COLUMN BaselineDate DATE DEFAULT NULL,
  ADD COLUMN StudyExit DATE DEFAULT NULL, 
  ADD COLUMN EyleaStartDate DATE DEFAULT NULL,
  ADD COLUMN AvastinStartDate DATE DEFAULT NULL,
  ADD COLUMN LucentisStartDate DATE DEFAULT NULL,
  ADD COLUMN InjectionCount INT(11) DEFAULT NULL,
  ADD COLUMN va_0 INT(11) DEFAULT NULL,
  ADD COLUMN va_1 INT(11) DEFAULT NULL,
  ADD COLUMN va_6 INT(11) DEFAULT NULL,
  ADD COLUMN va_12 INT(11) DEFAULT NULL,
  ADD COLUMN va_18 INT(11) DEFAULT NULL,
  ADD COLUMN va_24 INT(11) DEFAULT NULL,
  ADD COLUMN va_30 INT(11) DEFAULT NULL,
  ADD COLUMN va_36 INT(11) DEFAULT NULL,
  ADD COLUMN va_42 INT(11) DEFAULT NULL,
  ADD COLUMN va_48 INT(11) DEFAULT NULL,
  ADD COLUMN va_54 INT(11) DEFAULT NULL,
  ADD COLUMN IndexEye INT(11) DEFAULT NULL,
  ADD COLUMN SwitchExcl INT(11) DEFAULT NULL,
  ADD COLUMN RadioThermoExcl INT(11) DEFAULT NULL,
  ADD COLUMN VerteporfinThermoExcl INT(11) DEFAULT NULL,
  ADD COLUMN ClinicalTrialExcl INT(11) DEFAULT NULL,
  ADD COLUMN IntravitrealExcl INT(11) DEFAULT NULL,
  ADD COLUMN VitrectomyExcl INT(11) DEFAULT NULL,
  ADD COLUMN DiabeticRetinopathyExcl INT(11) DEFAULT NULL,
  ADD COLUMN RVOExcl INT(11) DEFAULT NULL,
  ADD COLUMN GlaucomaSurgExcl INT(11) DEFAULT NULL,
  ADD COLUMN CornealTransplantExcl INT(11) DEFAULT NULL,
  ADD COLUMN SubMacSurgExcl INT(11) DEFAULT NULL,
  ADD COLUMN AMDSurgExcl INT(11) DEFAULT NULL;

-- BaselineDate (date of first Eylea injection)
UPDATE AMDSyntheticEyleaArmMeta p
SET p.BaselineDate = (
SELECT MIN(i.EncounterDate)
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID
AND i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
);

-- EyleaStartDate
UPDATE AMDSyntheticEyleaArmMeta p
SET p.EyleaStartDate = (
SELECT i.EncounterDate
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND i.AntiVEGFInjection = 1
AND InjectedDrugDesc = "Eylea 2 mg/0.05ml (aflibercept)"
ORDER BY i.EncounterDate 
LIMIT 1
);

-- AvastinStartDate
UPDATE AMDSyntheticEyleaArmMeta p
SET p.AvastinStartDate = (
SELECT i.EncounterDate
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND i.AntiVEGFInjection = 1
AND InjectedDrugDesc IN ("Avastin 1.25 mg/0.05 ml", "Avastin 2 mg/0.08 ml", "Avastin 2.5 mg/0.10 ml")
ORDER BY i.EncounterDate 
LIMIT 1
);

-- LucentisStartDate
UPDATE AMDSyntheticEyleaArmMeta p
SET p.LucentisStartDate = (
SELECT i.EncounterDate
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND i.AntiVEGFInjection = 1
AND InjectedDrugDesc IN ("Lucentis 0.3 mg", "Lucentis 0.5 mg")
ORDER BY i.EncounterDate 
LIMIT 1
);

-- va_0 (va taken closest to baseline, up to a maxium of n days before 14 days before)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_0 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) + 14 BETWEEN 0 AND 14
);

-- va_1 (va at 1 to 7 days after baseline) (is this viable or ignore)?
UPDATE AMDSyntheticEyleaArmMeta p
SET va_1 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 1 AND 7
);

-- va_6 (va at 35 to 42 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_6 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 35 AND 42
);

-- va_12 (va at 77 to 83 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_12 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 77 AND 83
);

-- va_18 (va at 119 to 125 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_18 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 119 AND 125
);

-- va_24 (va at 161 to 167 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_24 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 161 AND 167
);

-- va_30 (va at 203 to 209 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_30 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 203 AND 209
);

-- va_36 (va at 245 to 251 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_36 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 245 AND 251
);

-- va_42 (va at 287 to 293 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_42 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 287 AND 293
);

-- va_48 (va at 329 to 335 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_48 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 329 AND 335
);

-- va_54 (va at 371 to 377 days after baseline)
UPDATE AMDSyntheticEyleaArmMeta p
SET va_54 = (
  SELECT MAX(v.ETDRS)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 371 AND 377
);

-- StudyExit (date as the date of week 54 va measurement)
UPDATE AMDSyntheticEyleaArmMeta p
SET StudyExit = (
  SELECT MIN(v.Date)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 371 AND 377 AND p.va_54 = v.ETDRS
);

-- InjectionCount (number injections reieved during study period)
UPDATE AMDSyntheticEyleaArmMeta p
SET InjectionCount = (
  SELECT COUNT(DISTINCT i.EncounterDate)
  FROM nvAMDInjections i
  WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND
  i.EncounterDate >= BaselineDate AND 
  i.EncounterDate <= StudyExit
);

-- IndexEye

-- SwitchExcl (1 if AvastinStartDate OR LucentisStartDate <= StudyExit)

-- RadioThermoExcl

-- VerteporfinThermoExcl

-- ClinicalTrialExcl

-- IntravitrealExcl

-- VitrectomyExcl

-- DiabeticRetinopathyExcl

-- RVOExcl

-- GlaucomaSurgExcl

-- CornealTransplantExcl

-- SubMacSurgExcl

-- AMDSurgExcl 

-- Export to .csv
