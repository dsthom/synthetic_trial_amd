-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)

/*
Script to create tables: 
nvAMD_surgery_indications
nvAMD_injections;
nvAMD_visual_acuity
*/

/*
nvAMDSurgeryIndications (all episodes that have a surgery indication for nvAMD ehr phenotype)
*/

DROP TABLE IF EXISTS nvAMD_surgery_indications;

CREATE TABLE nvAMD_surgery_indications AS
SELECT * FROM ETCSurgeryIndications 
WHERE 
      (IndicationDesc LIKE 'neovascular AMD %') 
OR 
      IndicationDesc IN ('wet age-related macular degeneration', 
                         'age-related macular degeneration',
                         'suspected neovascular AMD');

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

DROP TABLE IF EXISTS tempnvAMDInjections;

CREATE TABLE tempnvAMDInjections AS
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
  SELECT v.*
  FROM nvAMD_surgery_indications s 
  JOIN ETCVisualAcuity v
  ON s.PatientID = v.PatientID AND 
     s.EyeCode = v.EyeCode 
  WHERE v.RecordedNotation = 'LETTERSCORE';
  
CREATE INDEX idx_nvAMD_visual_acuity_pa_enc_ ON nvAMD_visual_acuity (`PatientID`, `EncounterDate`);

CREATE INDEX idx_nvAMD_visual_acuity_pa_eye_ ON nvAMD_visual_acuity (`PatientID`, `EyeCode`);