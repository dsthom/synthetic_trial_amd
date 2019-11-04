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
  ADD COLUMN BaselineDate DATE DEFAULT NULL,
  ADD COLUMN EstimatedStudyExit DATE DEFAULT NULL,
  ADD COLUMN StudyExit DATE DEFAULT NULL, 
  ADD COLUMN EyleaStartDate DATE DEFAULT NULL,
  ADD COLUMN AvastinStartDate DATE DEFAULT NULL,
  ADD COLUMN LucentisStartDate DATE DEFAULT NULL,
  ADD COLUMN StudyEligible INT(11) DEFAULT NULL,
  ADD COLUMN Bilateral INT(11) DEFAULT NULL,
  ADD COLUMN IndexEye INT(11) DEFAULT NULL,
  ADD COLUMN AgeAtBaseline INT(11) DEFAULT NULL,
  ADD COLUMN InjectionCount INT(11) DEFAULT NULL,
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
  ADD COLUMN SubMacSurgExcl INT(11) DEFAULT NULL;
  
-- BaselineDate (date of first Eylea injection)
UPDATE AMDSyntheticEyleaArmMeta p
SET p.BaselineDate = (
SELECT MIN(i.EncounterDate)
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID
AND i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
);
  
-- EstimatedStudyExit (the date 378 days (54 weeks * 7 days) onwards from baseline)
UPDATE AMDSyntheticEyleaArmMeta
SET EstimatedStudyExit = DATE_ADD(BaselineDate, INTERVAL 378 DAY);

-- StudyExit (date of va measurement closest---but prior---to EstimatedStudyExit)
UPDATE AMDSyntheticEyleaArmMeta p
SET StudyExit = (
  SELECT v.Date
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND 
        p.Eye = v.Eye AND 
        p.SiteID = v.SiteID AND
        v.Date > p.BaselineDate AND
        v.Date <= p.EstimatedStudyExit
  ORDER BY SQRT(DATEDIFF(v.Date, p.EstimatedStudyExit) ^ 2)
  LIMIT 1
);

-- EyleaStartDate
UPDATE AMDSyntheticEyleaArmMeta p
SET p.EyleaStartDate = (
SELECT MIN(i.EncounterDate)
FROM nvAMDInjections i
WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND i.AntiVEGFInjection = 1
AND InjectedDrugDesc = "Eylea 2 mg/0.05ml (aflibercept)"
);

-- Delete all eyes not admninistered Eylea
DELETE FROM AMDSyntheticEyleaArmMeta 
WHERE EyleaStartDate IS NULL;

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

-- StudyEligible (1 if Eylea is first VEGF inhibitor administered)
UPDATE AMDSyntheticEyleaArmMeta
SET StudyEligible = CASE 
                     WHEN EyleaStartDate IS NOT NULL AND
                          EyleaStartDate < AvastinStartDate OR
                          EyleaStartDate < LucentisStartDate
                     THEN 1
                     ELSE 0
                     END;

-- Bilateral (1 if > 1 eye in table)

================================
UPDATE AMDSyntheticEyleaArmMeta
SET Bilateral = 1

SELECT PatientID, COUNT(PatientID)
FROM AMDSyntheticEyleaArmMeta
WHERE 
GROUP BY PatientID;
================================

-- IndexEye (if > 1 eye affected, assign the eye diagnosed earliest THEN>>>>>)
================================

================================


-- AgeAtBaseline (years between perturbed date of bith and BaselineDate)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCPatientDetails d
ON p.PatientID = d.PatientID 
SET AgeAtBaseline = DATEDIFF(BaslineDate, PerturbedDateofBirth) / 365.25;

-- InjectionCount (number of injections reieved during study period)
UPDATE AMDSyntheticEyleaArmMeta p
SET InjectionCount = (
  SELECT COUNT(DISTINCT i.EncounterDate)
  FROM nvAMDInjections i
  WHERE p.PatientID = i.PatientID AND p.Eye = i.EyeCode AND p.SiteID = i.SiteID AND
  i.EncounterDate >= BaselineDate AND 
  i.EncounterDate <= StudyExit
);

-- SwitchExcl (1 if AvastinStartDate OR LucentisStartDate <= StudyExit)
UPDATE AMDSyntheticEyleaArmMeta
SET SwitchExcl = CASE 
                  WHEN AvastinStartDate >= BaselineDate AND AvastinStartDate < StudyExit OR
                       LucentisStartDate >= BaselineDate AND LucentisStartDate < StudyExit
                  THEN 1
                  ELSE 0
                  END;

-- RadioThermoExcl (stereotactic radiotherapy OR transpupillary thermotherapy OR %phytodynamic therapy before baseline)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.Eye = s.EyeCode AND
     p.SiteID = s.SiteID
  SET p.RadioThermoExcl =
  CASE
  WHEN s.ProcedureDesc IN ('stereotactic radiotherapy', 
                           'transpupillary thermotherapy',
                           '%photodynamic therapy%') AND
       s.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;
  
UPDATE AMDSyntheticEyleaArmMeta
SET RadioThermoExcl = 0
WHERE RadioThermoExcl IS NULL;

-- VerteporfinThermoExcl (PDR (as a proxy of verteporfin) within 7 days of baseline in non-study eye)
================================

================================

UPDATE AMDSyntheticEyleaArmMeta
SET VerteporfinThermoExcl = 0
WHERE VerteporfinThermoExcl IS NULL;

-- ClinicalTrialExcl (Macugen, Avastin or Luncetis before baseline---irregardless of whether during clinical trial)
================================

================================

UPDATE AMDSyntheticEyleaArmMeta
SET ClinicalTrialExcl = 0
WHERE ClinicalTrialExcl IS NULL;

-- IntravitrealExcl (intravitreal corticosteroid injection or implanttation before baseline)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCInjections i
  ON p.PatientID = i.PatientID AND
     p.Eye = i.EyeCode AND
     p.SiteID = i.SiteID
  SET p.IntravitrealExcl =
  CASE
  WHEN i.InjectedDrugDesc IN ('%dexamethasone%', 
                              '%Ozurdex%',
                              '%triamcinolone%',
                              '%Triesence%',
                              '%implant%') AND
       i.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;
  
UPDATE AMDSyntheticEyleaArmMeta
SET IntravitrealExcl = 0
WHERE IntravitrealExcl IS NULL;

-- VitrectomyExcl (%vitrectomy& before baseline)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.Eye = s.EyeCode AND
     p.SiteID = s.SiteID
  SET p.VitrectomyExcl =
  CASE
  WHEN s.ProcedureDesc LIKE '%vitrectomy%' AND
       s.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;

UPDATE AMDSyntheticEyleaArmMeta
SET VitrectomyExcl = 0
WHERE VitrectomyExcl IS NULL;  
  
-- DiabeticRetinopathyExcl (presence of ≥ 1 grade-diabetic reitnopathy as per ETDRS, NSC, or International)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCDRGrading d
  ON p.PatientID = d.PatientID AND
     p.Eye = d.EyeCode AND
     p.SiteID = d.SiteID
  SET p.DiabeticRetinopathyExcl =
  CASE
  WHEN d.DRGradeDesc LIKE '%PDR%' OR
       d.DRGradeDesc LIKE 'Scatter (PRP) Retinal Laser Scars Visible' OR 
       d.DRGradeDesc IN ('R1', 'R2', 'R3', 'M1', 'P') OR
       d.DRGradeDesc LIKE 'Proliferative DR' AND
       d.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;

UPDATE AMDSyntheticEyleaArmMeta
SET DiabeticRetinopathyExcl = 0
WHERE DiabeticRetinopathyExcl IS NULL;  

-- RVOExcl (retinal vein occlusion before baseline (inclusive of central, branch, hemi-branch, & macular-branch))
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCSurgeryIndications i
  ON p.PatientID = i.PatientID AND
     p.Eye = i.EyeCode AND
     p.SiteID = i.SiteID
  SET p.RVOExcl =
  CASE
  WHEN i.IndicationDesc LIKE '%retinal vein occlusion%' AND
       i.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;
  
UPDATE AMDSyntheticEyleaArmMeta
SET RVOExcl = 0
WHERE RVOExcl IS NULL; 

-- GlaucomaSurgExcl (trabeculectomy before baseline)
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.Eye = s.EyeCode AND
     p.SiteID = s.SiteID
  SET p.GlaucomaSurgExcl =
  CASE
  WHEN s.ProcedureDesc LIKE '%trabeculectomy%' AND
       s.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;

UPDATE AMDSyntheticEyleaArmMeta
SET GlaucomaSurgExcl = 0
WHERE GlaucomaSurgExcl IS NULL;

-- CornealTransplantExcl
UPDATE AMDSyntheticEyleaArmMeta p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.Eye = s.EyeCode AND
     p.SiteID = s.SiteID
  SET p.CornealTransplantExcl =
  CASE
  WHEN s.ProcedureDesc LIKE '%keratoplasty%' AND
       s.EncounterDate <= p.BaselineDate
  THEN 1
  ELSE 0
  END;
  
UPDATE AMDSyntheticEyleaArmMeta
SET CornealTransplantExcl = 0
WHERE CornealTransplantExcl IS NULL;

-- SubMacSurgExcl
# Any surgery for indications associated with AMD phenotype


UPDATE AMDSyntheticEyleaArmMeta
SET SubMacSurgExcl = 0
WHERE SubMacSurgExcl IS NULL;

================================
-- Update all Excl fills that are NULL to 0 (this is where there were no joins—or perhaps an anti-join update query for each?)
================================

-- Export to .csv (& convert variable names to snake case)
SELECT  
   AgeAtBaseline AS age_at_baseline,
   BaselineDate AS baseline_date,
   StudyExit AS study_exit,
   EyleaStartDate AS eylea_start_date,
   AvastinStartDate AS avastin_start_date,
   LucentisStartDate AS lucentis_start_date,
   InjectionCount AS injection_count,
   StudyElligible,
   IndexEye AS index_eye,
   SwitchExcl AS switch_excl,
   RadioThermoExcl AS radio_thermo_excl,
   VerteporfinThermoExcl AS verteporfin_thermo_excl,
   ClinicalTrialExcl AS clinical_trial_excl,
   IntravitrealExcl AS intravitreal_excl,
   VitrectomyExcl AS vitrectomy_excl,
   DiabeticRetinopathyExcl AS diabetic_retinopathy_excl,
   RVOExcl AS rvo_excl,
   GlaucomaSurgExcl AS glaucoma_excl,
   CornealTransplantExcl AS corneal_transplant_excl,
   SubMacSurgExcl AS sub_mac_surg_excl
FROM AMDSyntheticEyleaArmMeta;
  