-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)

/* 
Script to create & populate the study table: amd_synthetic_eylea_arm_study_table having run 
amd_irf_srf_large_tables.sql
*/ 
 
/*  
-- create table to be used for this study only
*/

DROP TABLE IF EXISTS amd_synthetic_eylea_arm_study_table;

CREATE TABLE amd_synthetic_eylea_arm_study_table AS
  SELECT si.PatientID, si.EyeCode, si.SiteID
  FROM nvAMD_surgery_indications si
  JOIN nvAMD_injections i
  ON si.PatientID = i.PatientID AND
     si.EyeCode = i.EyeCode
  WHERE i.InjectedDrugDesc LIKE '%Eylea%'
  GROUP BY PatientID, EyeCode;
  
-- RESTRICT TO THOSE WHO RECIEVED EYLEA AT SOME POINT.
  
CREATE INDEX idx_amd_synthetic_eylea_arm_study_table_pt_e ON amd_synthetic_eylea_arm_study_table (`PatientID`, `EyeCode`);

CREATE INDEX idx_amd_synthetic_eylea_arm_study_table_pt ON amd_synthetic_eylea_arm_study_table (`PatientID`);

/*
-- extend table with columns we will later populate
*/

ALTER TABLE amd_synthetic_eylea_arm_study_table
  ADD COLUMN patient_eye VARCHAR(255) DEFAULT NULL,
  ADD COLUMN gender VARCHAR(255) DEFAULT NULL,
  ADD COLUMN baseline_eylea_date DATE DEFAULT NULL,
  ADD COLUMN baseline_va_date DATE DEFAULT NULL,
  ADD COLUMN baseline_va INT(3) DEFAULT NULL,
  ADD COLUMN estimated_study_exit DATE DEFAULT NULL,
  ADD COLUMN study_exit DATE DEFAULT NULL, 
  ADD COLUMN study_exit_va INT(3) DEFAULT NULL,
  ADD COLUMN recent_eylea_injection DATE DEFAULT NULL,
  ADD COLUMN days_between_injection_and_exit_va INT(3) DEFAULT NULL,
  ADD COLUMN avastin_start_date DATE DEFAULT NULL,
  ADD COLUMN lucentis_start_date DATE DEFAULT NULL,
  ADD COLUMN affected_eyes INT(1) DEFAULT NULL,
  ADD COLUMN index_eye INT(1) DEFAULT NULL,
  ADD COLUMN index_date DATE DEFAULT NULL,
  ADD COLUMN age_at_baseline INT(3) DEFAULT NULL,
  ADD COLUMN third_injection_date DATE DEFAULT NULL,
  ADD COLUMN injection_count INT(3) DEFAULT NULL
  
  ADD COLUMN no_eylea_excl INT(11) DEFAULT 0, -- drop when code working
  
  -- ABC trial elligibility

  ADD COLUMN age_excl INT(1) DEFAULT 0,
  ADD COLUMN baseline_etdrs_excl INT(1) DEFAULT 0,
  ADD COLUMN radio_thermo_excl INT(1) DEFAULT 0,
  ADD COLUMN verteporfin_thermo_excl INT(1) DEFAULT 0,
  ADD COLUMN clinical_trial_excl INT(1) DEFAULT 0,
  ADD COLUMN intravitreal_excl INT(1) DEFAULT 0,
  ADD COLUMN vitrectomy_excl INT(1) DEFAULT 0,
  ADD COLUMN diabetic_retinopathy_excl INT(1) DEFAULT 0,
  ADD COLUMN rvo_excl INT(1) DEFAULT 0,
  ADD COLUMN trabeculectomy_excl INT(1) DEFAULT 0,
  ADD COLUMN corneal_transplant_excl INT(1) DEFAULT 0,
  ADD COLUMN sub_mac_surg_excl INT(1) DEFAULT 0,
  ADD COLUMN haemorrhage_excl INT(1) DEFAULT 0,
  ADD COLUMN subfoveal_excl INT(1) DEFAULT 0,
  ADD COLUMN other_cnv_excl INT(1) DEFAULT 0,
  ADD COLUMN tear_excl INT(1) DEFAULT 0,
  ADD COLUMN concurrent_excl INT(1) DEFAULT 0,
  ADD COLUMN vitreous_haemorrhage_excl INT(1) DEFAULT 0,
  ADD COLUMN rheg_hole_excl INT(1) DEFAULT 0,
  ADD COLUMN uveitis_excl INT(1) DEFAULT 0,
  ADD COLUMN infection_excl INT(1) DEFAULT 0,
  ADD COLUMN intraocular_surg_excl INT(1) DEFAULT 0,
  ADD COLUMN glaucoma_excl INT(1) DEFAULT 0,

  
  -- study-specific elligibility
  ADD COLUMN previous_vegf_excl INT(1) DEFAULT 0,
  ADD COLUMN switch_excl INT(1) DEFAULT 0,
  ADD COLUMN incomplete_loading_excl INT(1) DEFAULT 0,
  ADD COLUMN missing_covariates_excl INT(1) DEFAULT 0,
  
  ADD COLUMN ineligibility INT(1) DEFAULT 0;

/*
patient_eye
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET patient_eye = CONCAT(PatientID, '-', EyeCode);

/*
gender
*/

UPDATE amd_synthetic_eylea_arm_study_table s
JOIN ETCPatientDetails p
ON s.PatientID = p.PatientID
SET s.gender = p.Gender;

/*
-- baseline_eylea_date (date of first Eylea injection)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET p.baseline_eylea_date = (
SELECT MIN(i.EncounterDate)
FROM nvAMD_injections i
WHERE p.PatientID = i.PatientID AND 
      p.EyeCode = i.EyeCode AND
      i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
);

/*
baseline_va_date (date of va measurement closest to baseline (up to a maximum of
30 days beforehand))
*/

UPDATE amd_synthetic_eylea_arm_study_table s
SET baseline_va_date = (
  SELECT MAX(v.EncounterDate)
  FROM nvAMD_visual_acuity v
  WHERE v.PatientID = s.PatientID AND
        v.EyeCode = s.EyeCode AND
        DATEDIFF(s.baseline_eylea_date, v.EncounterDate) BETWEEN 0 AND 30 AND
        v.EncounterDate <= s.baseline_eylea_date
);

/*
baseline_va (highest etdrs measurement taken on baseline_va_date)
*/

UPDATE amd_synthetic_eylea_arm_study_table s
SET s.baseline_va = (
SELECT MAX(v.ETDRS)
FROM nvAMD_visual_acuity v
WHERE s.PatientID = v.PatientID AND 
      s.EyeCode = v.EyeCode AND
      s.baseline_eylea_date = v.EncounterDate
);

/*
-- estimated_study_exit (the date 378 days (54 weeks * 7 days) onwards from baseline)
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET estimated_study_exit = 
  DATE_ADD(baseline_eylea_date, INTERVAL 378 DAY);

/*
-- study_exit (date of va measurement closest---but prior---to 
estimated_study_exit--akin to last observation carried forward)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET study_exit = (
  SELECT MAX(v.EncounterDate)
  FROM nvAMD_visual_acuity v
  WHERE p.PatientID = v.PatientID AND 
        p.EyeCode = v.EyeCode AND 
        v.EncounterDate > p.baseline_eylea_date AND
        v.EncounterDate <= p.estimated_study_exit
  LIMIT 1
);

/*
-- study_exit_va (highest etdrs measurement taken on baseline_va_date)S)
*/

UPDATE amd_synthetic_eylea_arm_study_table s
SET s.study_exit_va = (
SELECT MAX(v.ETDRS)
FROM nvAMD_visual_acuity v
WHERE s.PatientID = v.PatientID AND 
      s.EyeCode = v.EyeCode AND
      s.study_exit = v.EncounterDate
);

/*
--recent_eylea_injection
*/

UPDATE amd_synthetic_eylea_arm_study_table s
SET s.recent_eylea_injection = (
  SELECT MAX(i.EncounterDate)
  FROM nvAMD_injections i
  WHERE s.PatientID = i.PatientID AND
        s.EyeCode = i.EyeCode AND
        i.EncounterDate <= study_exit AND
        i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
);

/* 
-- days_between_injection_and_exit_va
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET days_between_injection_and_exit_va = 
  DATEDIFF(study_exit, last_eylea_injection);

/*
-- avastin_start_date
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET p.avastin_start_date = (
SELECT MIN(i.EncounterDate)
FROM nvAMD_injections i
WHERE p.PatientID = i.PatientID AND 
      p.EyeCode = i.EyeCode AND 
      i.AntiVEGFInjection = 1 AND
      i.InjectedDrugDesc IN ("Avastin 1.25 mg/0.05 ml", 
                             "Avastin 2 mg/0.08 ml", 
                             "Avastin 2.5 mg/0.10 ml")
ORDER BY i.EncounterDate 
LIMIT 1
);

/*
-- lucentis_start_date
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET p.lucentis_start_date = (
SELECT MIN(i.EncounterDate)
FROM nvAMD_injections i
WHERE p.PatientID = i.PatientID AND 
      p.EyeCode = i.EyeCode AND
      i.AntiVEGFInjection = 1 AND 
      i.InjectedDrugDesc IN ("Lucentis 0.3 mg", 
                             "Lucentis 0.5 mg", 
                             "Clinical-trial drug (Avastin or Lucentis)")
ORDER BY i.EncounterDate 
LIMIT 1
);


/*
-- affected_eyes (number of eyes with surgery indications for AMD that were treated with Eylea)
*/

UPDATE amd_synthetic_eylea_arm_study_table p1
	INNER JOIN (
		SELECT PatientID, COUNT(PatientID) AS affected_eyes
		FROM amd_synthetic_eylea_arm_study_table p2
		GROUP BY PatientID
		) p3
	ON p1.PatientID = p3.PatientID
SET p1.affected_eyes = p3.affected_eyes;

/*
-- index_eye (if > 1 EyeCode affected, assign the EyeCode diagnosed earliest & then random EyeCode if tied)
*/

-- if one EyeCode affected, assign only as index

UPDATE amd_synthetic_eylea_arm_study_table
SET index_eye = 1
WHERE affected_eyes = 1;

-- if two eyes, assign earliest diagnosed

UPDATE amd_synthetic_eylea_arm_study_table p1,
	(SELECT MIN(baseline_eylea_date) AS index_date, PatientID, EyeCode
	FROM amd_synthetic_eylea_arm_study_table
	WHERE index_eye IS NULL
	GROUP BY PatientID
	HAVING COUNT(DISTINCT baseline_eylea_date) > 1) p2
SET index_eye = 1
WHERE p1.PatientID = p2.PatientID AND 
      p1.baseline_eylea_date = p2.index_date;

-- if two eyes diagnosed on same day, assign index at random
DROP TEMPORARY TABLE IF EXISTS SYN_randomly_selected_eyes;

CREATE TEMPORARY TABLE SYN_randomly_selected_eyes AS
SELECT * FROM (
    SELECT s1.patient_eye, s1.PatientID, s1.index_eye, s1.affected_eyes
    FROM amd_synthetic_eylea_arm_study_table s1
    INNER JOIN amd_synthetic_eylea_arm_study_table s2 ON 
    s1.PatientID = s2.PatientID
    ORDER BY RAND(123)
) AS random_eyes
GROUP BY PatientID
HAVING SUM(index_eye) IS NULL;

UPDATE amd_synthetic_eylea_arm_study_table s
JOIN SYN_randomly_selected_eyes r
ON s.patient_eye = r.patient_eye
SET s.index_eye = 1;

UPDATE amd_synthetic_eylea_arm_study_table
SET index_eye = 0
WHERE index_eye IS NULL;

-- check that all patients have 1 index EyeCode assigned

SELECT COUNT(*)
FROM amd_synthetic_eylea_arm_study_table
GROUP BY PatientID
HAVING COUNT(index_eye) < 1;

/*
-- index_date
*/

UPDATE amd_synthetic_eylea_arm_study_table p1,
  (SELECT baseline_eylea_date AS index_date, PatientID
  FROM amd_synthetic_eylea_arm_study_table
  WHERE index_eye = 1
  ) p2
SET p1.index_date = p2.index_date
WHERE p1.PatientID = p2.PatientID;

/*
-- age_at_baseline (years between perturbed date of birth and baseline_eylea_date)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCPatientDetails d
ON p.PatientID = d.PatientID 
SET age_at_baseline = 
  FLOOR(DATEDIFF(p.baseline_eylea_date, d.PerturbedDateofBirth) / 365.25);

/*
--third_injection_date
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET third_injection_date = (
  SELECT MIN(DISTINCT i.EncounterDate)
  FROM nvAMD_injections i
  WHERE i.patient_eye = p.patient_eye AND
        i.cumulative_injection_count = 3
);

/*
-- injection_count (number of Eylea injections recieved during study period)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
SET injection_count = (
  SELECT COUNT(DISTINCT i.EncounterDate)
  FROM nvAMD_injections i
  WHERE p.PatientID = i.PatientID AND 
        p.EyeCode = i.EyeCode AND 
        i.EncounterDate >= p.baseline_eylea_date AND 
        i.EncounterDate <= p.study_exit AND
        i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
);


/*
no_eylea_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table 
SET no_eylea_excl = 1
WHERE baseline_eylea_date IS NULL;


/*
age_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET age_excl = 1
WHERE age_at_baseline < 51;

/*
baseline_etdrs_excl (1 if eye's baseline_va was not 25 to 73 inclusively (in 
allignment with NICE guidelines))
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET baseline_etdrs_excl = 1
WHERE baseline_va < 25 OR
      baseline_va > 73;

/*
-- radio_thermo_excl (stereotactic radiotherapy OR transpupillary thermotherapy OR %phytodynamic therapy before baseline)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.EyeCode = s.EyeCode
  SET p.radio_thermo_excl = 1
  WHERE s.ProcedureDesc IN ('stereotactic radiotherapy', 
                           'transpupillary thermotherapy',
                           '%photodynamic therapy%') AND
       s.EncounterDate <= p.baseline_eylea_date;

/*
-- verteporfin_thermo_excl (photodynamic therapy (as a proxy of verteporfin) within 7 days of index_date)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID
  SET p.verteporfin_thermo_excl = 1
  WHERE s.ProcedureDesc LIKE '%photodynamic therapy%' AND
       DATEDIFF(p.index_date, s.EncounterDate) <= 7;

/*
-- clinical_trial_excl (Avastin, Lucentis or Macugen before baseline---irregardless of whether during clinical trial).
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCInjections i
  ON p.PatientID = i.PatientID
  SET p.clinical_trial_excl = 1
  WHERE i.InjectedDrugDesc IN ('%Macugen%',
                              '%Avastin%',
                              '%Lucentis%',
                              'HARRIER trial drug',
                              'LEAVO trial drug') AND
        i.EncounterDate <= p.baseline_eylea_date;

/*
-- intravitreal_excl (intravitreal corticosteroid injection or implantation before baseline)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCInjections i
  ON p.PatientID = i.PatientID AND
     p.EyeCode = i.EyeCode
  SET p.intravitreal_excl = 1
  WHERE i.InjectedDrugDesc IN ('%dexamethasone%', 
                              '%Ozurdex%',
                              '%triamcinolone%',
                              '%Triesence%',
                              '%implant%') AND
        i.EncounterDate <= p.baseline_eylea_date;

/*
-- vitrectomy_excl (%vitrectomy& before baseline)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.EyeCode = s.EyeCode
  SET p.vitrectomy_excl = 1
  WHERE s.ProcedureDesc LIKE '%vitrectomy%' AND
        s.EncounterDate <= p.baseline_eylea_date;

/*
-- diabetic_retinopathy_excl (presence of ≥ 1 grade-diabetic reitnopathy as per ETDRS, NSC, or International)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCDRGrading d
  ON p.PatientID = d.PatientID AND
     p.EyeCode = d.EyeCode
  SET p.diabetic_retinopathy_excl = 1
  WHERE d.DRGradeDesc LIKE '%PDR%' OR
        d.DRGradeDesc LIKE 'Scatter (PRP) Retinal Laser Scars Visible' OR 
        d.DRGradeDesc IN ('R2', 'R3', 'M1', 'P') OR
        d.DRGradeDesc IN ('Moderate NPDR', 'Severe NPDR') OR
        d.DRGradeDesc LIKE 'Proliferative DR' AND
        d.EncounterDate <= p.baseline_eylea_date;

/*
-- rvo_excl (retinal vein occlusion before baseline (inclusive of central, branch, hemi-branch, & macular-branch))
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications i
  ON p.PatientID = i.PatientID AND
     p.EyeCode = i.EyeCode
  SET p.rvo_excl = 1
  WHERE i.IndicationDesc LIKE '%retinal vein occlusion%' AND
       i.EncounterDate <= p.baseline_eylea_date;

/*
-- trabeculectomy_excl (trabeculectomy before baseline)
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.EyeCode = s.EyeCode
  SET p.glaucoma_excl = 1
  WHERE s.ProcedureDesc LIKE '%trabeculectomy%' AND
        s.EncounterDate <= p.baseline_eylea_date;

/*
-- corneal_transplant_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgery s
  ON p.PatientID = s.PatientID AND
     p.EyeCode = s.EyeCode
  SET p.corneal_transplant_excl = 1
  WHERE s.ProcedureDesc LIKE '%keratoplasty%' AND
        s.EncounterDate <= p.baseline_eylea_date;

/*
-- sub_mac_surg_excl (any surgery for indications associated with AMD phenotype)
*/


/*
-- haemorrhage_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
  SET p.haemorrhage_excl = 1
  WHERE s.IndicationDesc IN (
  'foeveal subretinal haemorrhage',
  'subretinal haemorrhage in centre of lesion',
  'foveal sub RPE haemorrhage'
  ) AND
  s.EncounterDate <= p.baseline_eylea_date;
  
/*
-- subfoveal_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
   SET p.subfoveal_excl = 1
   WHERE s.IndicationDesc IN (
   'sub-foveal fibrosis',
   'foveal involving atrophy'
   ) AND
   s.EncounterDate <= p.baseline_eylea_date;
   
/*
-- other_cnv_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID
  SET p.other_cnv_excl = 1
  WHERE s.other_cnv_excl IN (
  'choroidal neovascular membrane associated with presumed ocular histoplasmosis syndrome',
  'sub-foveal CNV',
  'juxtafoveal CNV',
  'peripapillary CNV',
  'extrafoveal CNV',
  'multifocal CNV',
  'peripheral CNV',
  'CNV outside posterior pole',
  'pathological myopia',
  ) AND
  s.EncounterDate <= p.baseline_eylea_date;

/*
-- tear_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
  SET p.tear_excl = 1
  WHERE s.IndicationDesc LIKE 'RPE rip / tear' OR
        s.IndicationDesc LIKE '%retinal tear%' AND
  s.EncounterDate <= p.baseline_eylea_date;

/*
-- concurrent_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
  SET p.concurrent_excl = 1
  WHERE s.IndicationDesc IN (
  '%cataract%',
  '%macular oedema%'
  '%diabetic retinopathy%', 
  'diabetic maculopathy%',
  'diabetic papillopathy'
  ) AND
  s.EncounterDate >= p.baseline_eylea_date AND
  s.EncounterDate <= p.study_exit_va;
  
/*
-- vitreous_haemorrhage_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
   SET p.vitreous_haemorrhage_excl = 1
   WHERE s.IndicationDesc LIKE '%vitreous haemorrhage%' AND
         DATEDIFF(p.Baseline_eylea_date, s.EncounterDate) <= 90;

/*
-- rheg_hole_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID AND
   p.EyeCode = s.EyeCode
   SET p.rheg_hole_excl = 1
   WHERE s.IndicationDesc IN(
   '%rhegmatogenous%detachment%',
   '%macular hole%'
   ) AND
   s.EncounterDate <= p.baseline_eylea_date;
   
/*
-- uveitis_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID 
  SET p.uveitis_excl = 1
  WHERE s.IndicationDesc IN(
  'idiopathic uveitis',
  'Lyme disease uveitis'
  ) AND
  s.EncounterDate <= p.baseline_eylea_date;
  
/*
-- infection_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table p
JOIN ETCSurgeryIndications s
ON p.PatientID = s.PatientID 
  SET infection_excl = 1
  WHERE IndicationDesc = IN(
  '%conjunctivitis%',
  '%keratitis%',
  '%scleritis%', 
  '%endophthalmitis%' 
  ) AND
  DATEDIFF(p.baseline_eylea_date, s.EncounterDate) <= 90;

/*
-- intraocular_surg_excl
*/


/*
-- glaucoma_excl
*/


/*
-- previous_vegf_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET previous_vegf_excl = 1
  WHERE avastin_start_date <= baseline_eylea_date OR
        lucentis_start_date <= baseline_eylea_date;

/*
-- switch_excl (1 if avastin_start_date is after baseline_eyelea_date AND lucentis_start_date <= study_exit)
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET switch_excl = 1 
  WHERE avastin_start_date >= baseline_eylea_date AND avastin_start_date < study_exit OR
        lucentis_start_date >= baseline_eylea_date AND lucentis_start_date < study_exit;

/*
-- incomplete_loading_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET incomplete_loading_excl = 1
WHERE DATEDIFF(third_injection_date, baseline_eylea_date) > 70;

/*
-- missing_covariates_excl
*/

UPDATE amd_synthetic_eylea_arm_study_table
SET missing_covariates_excl = 1
WHERE gender IS NULL OR
      baseline_va IS NULL OR
      age_at_baseline IS NULL;
      
/*
ineligibility (if all excl = 0)
/*

/*
-- Export to .csv
*/
--Write actual code or use kale into R.

SELECT *
FROM amd_synthetic_eylea_arm_study_table;

/*
-- Export va measurements for those fufilinng abc crtieria to .csv
*/

/*

TO DO:
* ineligibility
*/