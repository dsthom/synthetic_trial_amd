-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)

/*
Script to create tables: 
nvAMD_surgery_indications
nvAMD_injections;
nvAMD_visual_acuity
nvAMD_oct
*/

/*
nvAMDSurgeryIndications (all episodes that have a surgery indication for nvAMD ehr phenotype)
*/

DROP TABLE IF EXISTS nvAMD_surgery_indications;

CREATE TABLE nvAMD_surgery_indications AS
SELECT *
FROM ETCSurgeryIndications 
WHERE IndicationDesc IN (
  'age-related macular degeneration',
  'neovascular AMD (classic no occult CNV)',
  'neovascular AMD (idiopathic polypoidal choroidal vasculopathy)',
  'neovascular AMD (minimally classic CNV)',
  'neovascular AMD (occult no classic CNV)',
  'neovascular AMD (predominantly classic CNV)',
  'neovascular AMD (retinal angiomatous proliferation)',
  'neovascular AMD (subtype not specified)',
  'suspected neovascular AMD',
  'wet age-related macular degeneration');

CREATE INDEX idx_nvAMD_surgery_indications_pt_st_e ON nvAMD_surgery_indications (`PatientID`, `SiteID`, `EyeCode`);

/*
nvAMDInjections (all epsidoes for nvAMD cohort wherein Avastin, Luncentis or Eylea was administered)
*/

DROP TABLE IF EXISTS nvAMD_injections;

CREATE TABLE nvAMD_injections AS
SELECT i.* 
FROM nvAMD_surgery_indications s 
JOIN ETCInjections i 
ON s.PatientID = i.PatientID AND 
   s.EyeCode = i.EyeCode AND 
   s.SiteID = i.SiteID AND
   s.EncounterDate = i.EncounterDate 
WHERE i.AntiVEGFInjection = 1
AND InjectedDrugDesc IN ("Avastin 1.25 mg/0.05 ml", 
                         "Avastin 2 mg/0.08 ml", 
                         "Avastin 2.5 mg/0.10 ml", 
                         "Eylea 2 mg/0.05ml (aflibercept)", 
                         "Lucentis 0.3 mg", 
                         "Lucentis 0.5 mg",
                         "Clinical-trial drug (Avastin or Lucentis)");

CREATE INDEX idx_nvAMD_injections_pt_st_e ON nvAMD_injections (`PatientID`, `SiteID`, `EyeCode`);

ALTER TABLE nvAMD_injections
    ADD COLUMN patient_eye VARCHAR(255) DEFAULT NULL,
    ADD COLUMN cumulative_injection_count INT(11) DEFAULT NULL,
    ADD COLUMN days_until_next_injection INT(11) DEFAULT NULL,
    ADD COLUMN days_since_last_injection INT(11) DEFAULT NULL;

-- patient_eye

UPDATE nvAMD_injections
SET patient_eye = CONCAT(PatientID, '-', EyeCode);

CREATE INDEX idx_nvAMD_injections_pa_enc_ ON nvAMD_injections (`patient_eye`, `EncounterDate`);

-- cumulative_injection_count 

DROP TEMPORARY TABLE IF EXISTS tempnvAMDInjections;

CREATE TEMPORARY TABLE tempnvAMDInjections AS
	SELECT *
	FROM nvAMD_injections;
	
CREATE INDEX idx_tempnvAMDInjections_pa_enc_ ON tempnvAMDInjections (`patient_eye`, `EncounterDate`);

UPDATE nvAMD_injections i
SET i.cumulative_injection_count = (
	SELECT COUNT(DISTINCT ii.EncounterDate) 
    FROM  tempnvAMDInjections ii
    WHERE i.patient_eye = ii.patient_eye AND
          i.EncounterDate >= ii.EncounterDate
);

-- days_until_next_injection

UPDATE nvAMD_injections i
LEFT JOIN nvAMD_injections ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_injection_count = ii.cumulative_injection_count - 1
  SET i.days_until_next_injection =
  DATEDIFF(ii.EncounterDate, i.EncounterDate);

-- days_since_last_injection

UPDATE nvAMD_injections i
LEFT JOIN nvAMD_injections ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_injection_count - 1 = ii.cumulative_injection_count
  SET i.days_since_last_injection =
  DATEDIFF(i.EncounterDate, ii.EncounterDate);

/*
nvAMD_visual_acuity
*/

DROP TABLE IF EXISTS nvAMD_visual_acuity;

CREATE TABLE nvAMD_visual_acuity AS
SELECT SiteID,
       PatientID,
       Eye AS EyeCode,
       EncounterID,
       Date AS EncounterDate,
       MAX(ETDRS) AS max_etdrs
FROM VA_simple_meta
WHERE (
	PatientID,
	Eye) IN (
	SELECT PatientID, EyeCode 
	FROM nvAMD_surgery_indications)
	GROUP BY PatientID, EyeCode, EncounterDate;
  
CREATE INDEX idx_nvAMD_visual_acuity_pa_enc_ ON nvAMD_visual_acuity (`PatientID`, `EncounterDate`);
CREATE INDEX idx_nvAMD_visual_acuity_pa_eye_ ON nvAMD_visual_acuity (`PatientID`, `EyeCode`);

ALTER TABLE nvAMD_visual_acuity
  ADD COLUMN patient_eye VARCHAR(255) DEFAULT NULL,
  ADD COLUMN cumulative_va_count INT(3) DEFAULT NULL,
  ADD COLUMN days_until_next_va INT(3) DEFAULT NULL,
  ADD COLUMN days_since_last_va INT(3) DEFAULT NULL;

/*
-- patient_eye
*/

UPDATE nvAMD_visual_acuity
SET patient_eye = 
  CONCAT(PatientID, '-', EyeCode);
  
CREATE INDEX idx_nvAMD_visual_acuity_patient_eye_encounter_date ON nvAMD_visual_acuity (`patient_eye`, `EncounterDate`);

/*
-- cumulative_va_count (count starts BEFORE baseline)
*/

DROP TEMPORARY TABLE IF EXISTS tempnvAMD_visual_acuity;

CREATE TEMPORARY TABLE tempnvAMD_visual_acuity AS
	SELECT *
	FROM nvAMD_visual_acuity;
	
CREATE INDEX idx_tempnvAMD_visual_acuity_pa_enc_ ON tempnvAMD_visual_acuity (`patient_eye`, `EncounterDate`);

UPDATE nvAMD_visual_acuity i
SET i.cumulative_va_count = (
	SELECT COUNT(DISTINCT ii.EncounterDate) 
    FROM  tempnvAMD_visual_acuity ii
    WHERE i.patient_eye = ii.patient_eye AND
          i.EncounterDate >= ii.EncounterDate
);

/*
-- days_until_next_va
*/

UPDATE nvAMD_visual_acuity i
LEFT JOIN nvAMD_visual_acuity ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_va_count = ii.cumulative_va_count - 1
  SET i.days_until_next_va =
  DATEDIFF(ii.EncounterDate, i.EncounterDate);

/*
-- days_since_last_va
*/

UPDATE nvAMD_visual_acuity i
LEFT JOIN nvAMD_visual_acuity ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_va_count - 1 = ii.cumulative_va_count
  SET i.days_since_last_va =
  DATEDIFF(i.EncounterDate, ii.EncounterDate);

/*
nvAMD_oct (all OCT scans for nvAMD cohort)
*/

DROP TABLE IF EXISTS nvAMD_oct;

CREATE TABLE nvAMD_oct AS
  SELECT o.*
  FROM nvAMD_surgery_indications s
  JOIN ETCOCT o
  ON s.PatientID = o.PatientID AND
     s.EyeCode = o.EyeCode;

CREATE INDEX idx_nvAMD_oct_pa_enc ON nvAMD_oct (`PatientID`, `EncounterDate`);
CREATE INDEX idx_nnvAMD_oct_pa_eye ON nvAMD_oct (`PatientID`, `EyeCode`);

ALTER TABLE nvAMD_oct
  ADD COLUMN patient_eye VARCHAR(255) DEFAULT NULL,
  ADD COLUMN cumulative_oct_count INT(3) DEFAULT NULL,
  ADD COLUMN days_until_next_oct INT(3) DEFAULT NULL,
  ADD COLUMN days_since_last_oct INT(3) DEFAULT NULL;
  
/*
-- patient_eye
*/

UPDATE nvAMD_oct
SET patient_eye = 
  CONCACT(PatientID, '-', EyeCode);

/*
-- cumulative_oct_count (count starts BEFORE baseline)
*/

DROP TEMPORARY TABLE IF EXISTS tempnvAMD_oct;

CREATE TEMPORARY TABLE tempnvAMD_oct AS
	SELECT *
	FROM nvAMD_oct;
	
CREATE INDEX idx_tempnvAMD_oct_pa_enc_ ON tempnvAMD_oct (`patient_eye`, `EncounterDate`);

UPDATE nvAMD_oct i
SET i.cumulative_oct_count = (
	SELECT COUNT(DISTINCT ii.EncounterDate) 
    FROM tempnvAMD_oct ii
    WHERE i.patient_eye = ii.patient_eye AND
          i.EncounterDate >= ii.EncounterDate
);

/*
-- days_until_next_oct
*/

UPDATE nvAMD_oct i
LEFT JOIN nvAMD_oct ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_oct_count = ii.cumulative_oct_count - 1
  SET i.days_until_next_oct =
  DATEDIFF(ii.EncounterDate, i.EncounterDate);

/*
-- days_since_last_oct
*/

UPDATE nvAMD_oct i
LEFT JOIN nvAMD_oct ii
ON i.patient_eye = ii.patient_eye AND
   i.cumulative_oct_count - 1 = ii.cumulative_oct_count
  SET i.days_since_last_oct =
  DATEDIFF(i.EncounterDate, ii.EncounterDate);

/*
SCRIPT END
*/