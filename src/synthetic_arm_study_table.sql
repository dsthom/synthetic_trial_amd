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
    SELECT PatientID, EyeCode, SiteID
    FROM nvAMD_surgery_indications
    GROUP BY PatientID, EyeCode;
    
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
    ADD COLUMN baseline_va INT(11) DEFAULT NULL,
    ADD COLUMN estimated_study_exit DATE DEFAULT NULL,
    ADD COLUMN study_exit DATE DEFAULT NULL, 
    ADD COLUMN baseline_eylea_date DATE DEFAULT NULL,
    ADD COLUMN avastin_start_date DATE DEFAULT NULL,
    ADD COLUMN lucentis_start_date DATE DEFAULT NULL,
    ADD COLUMN avastin_lucentis_before_eylea INT(11) DEFAULT NULL,
    ADD COLUMN affected_eyes INT(11) DEFAULT NULL,
    ADD COLUMN index_eye INT(11) DEFAULT NULL,
    ADD COLUMN index_date DATE DEFAULT NULL,
    ADD COLUMN age_at_baseline INT(11) DEFAULT NULL,
    ADD COLUMN injection_count INT(11) DEFAULT NULL,
    ADD COLUMN no_eylea_excl INT(11) DEFAULT 0,
    ADD COLUMN switch_excl INT(11) DEFAULT 0,
    ADD COLUMN radio_thermo_excl INT(11) DEFAULT 0,
    ADD COLUMN verteporfin_thermo_excl INT(11) DEFAULT 0,
    ADD COLUMN clinical_trial_excl INT(11) DEFAULT 0,
    ADD COLUMN intravitreal_excl INT(11) DEFAULT 0,
    ADD COLUMN vitrectomy_excl INT(11) DEFAULT 0,
    ADD COLUMN diabetic_retinopathy_excl INT(11) DEFAULT 0,
    ADD COLUMN rvo_excl INT(11) DEFAULT 0,
    ADD COLUMN glaucoma_excl INT(11) DEFAULT 0,
    ADD COLUMN corneal_transplant_excl INT(11) DEFAULT 0,
    ADD COLUMN sub_mac_surg_excl INT(11) DEFAULT NULL;

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
	SELECT MAX(v.RecordedNotationBestCorrected)
	FROM nvAMD_visual_acuity v
	WHERE s.PatientID = v.PatientID AND 
	      s.EyeCode = v.EyeCode AND
	      s.baseline_eylea_date = v.EncounterDate
	);

  /*
  -- estimated_study_exit (the date 378 days (54 weeks * 7 days) onwards from baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET estimated_study_exit = DATE_ADD(baseline_eylea_date, INTERVAL 378 DAY);

  /*
  -- study_exit (date of va measurement closest---but prior---to estimated_study_exit)
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
  -- baseline_eylea_date
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  SET p.baseline_eylea_date = (
  SELECT MIN(i.EncounterDate)
  FROM nvAMD_injections i
  WHERE p.PatientID = i.PatientID AND 
        p.EyeCode = i.EyeCode AND
        i.AntiVEGFInjection = 1 AND
        i.InjectedDrugDesc = "Eylea 2 mg/0.05ml (aflibercept)"
  );

  /*
  -- avastin_start_date
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  SET p.avastin_start_date = (
  SELECT i.EncounterDate
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
  SELECT i.EncounterDate
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
  -- avastin_lucentis_before_eylea (1 if Eylea is first VEGF inhibitor administered)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET avastin_lucentis_before_eylea = CASE 
                       WHEN avastin_start_date <= baseline_eylea_date  OR
                            lucentis_start_date <= baseline_eylea_date
                       THEN 1
                       ELSE 0
                       END;

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
  WHERE p1.PatientID = p2.PatientID AND p1.baseline_eylea_date = p2.index_date;

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
  -- age_at_baseline (years between perturbed date of bith and baseline_eylea_date)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCPatientDetails d
  ON p.PatientID = d.PatientID 
  SET age_at_baseline = DATEDIFF(p.baseline_eylea_date, d.PerturbedDateofBirth) / 365.25;

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
  SET no_eylea_excl =  CASE
                       WHEN  baseline_eylea_date IS NULL
                       THEN 1
                       ELSE 0
                       END;

  /*
  -- switch_excl (1 if avastin_start_date OR lucentis_start_date <= study_exit)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET switch_excl = CASE 
                    WHEN avastin_start_date >= baseline_eylea_date AND avastin_start_date < study_exit OR
                         lucentis_start_date >= baseline_eylea_date AND lucentis_start_date < study_exit
                    THEN 1
                    ELSE 0
                    END;

  /*
  -- radio_thermo_excl (stereotactic radiotherapy OR transpupillary thermotherapy OR %phytodynamic therapy before baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgery s
    ON p.PatientID = s.PatientID AND
       p.EyeCode = s.EyeCode
    SET p.radio_thermo_excl =
    CASE
    WHEN s.ProcedureDesc IN ('stereotactic radiotherapy', 
                             'transpupillary thermotherapy',
                             '%photodynamic therapy%') AND
         s.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- verteporfin_thermo_excl (photodynamic therapy (as a proxy of verteporfin) within 7 days of index_date)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgery s
    ON p.PatientID = s.PatientID AND
       p.EyeCode = s.EyeCode
    SET p.verteporfin_thermo_excl =
    CASE
    WHEN s.ProcedureDesc LIKE '%photodynamic therapy%' AND
         DATEDIFF(p.index_date, s.EncounterDate) <= 7
    THEN 1
    ELSE 0
    END;

  /*
  -- clinical_trial_excl (Macugen before baseline---irregardless of whether during clinical trial).
  Avastin or Luncetis before baseline previously excluded beforeassinging index_eye
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCInjections i
    ON p.PatientID = i.PatientID AND
       p.EyeCode = i.EyeCode
    SET p.clinical_trial_excl =
    CASE
    WHEN i.InjectedDrugDesc LIKE '%Macugen%' AND
         i.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- intravitreal_excl (intravitreal corticosteroid injection or implantation before baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCInjections i
    ON p.PatientID = i.PatientID AND
       p.EyeCode = i.EyeCode
    SET p.intravitreal_excl =
    CASE
    WHEN i.InjectedDrugDesc IN ('%dexamethasone%', 
                                '%Ozurdex%',
                                '%triamcinolone%',
                                '%Triesence%',
                                '%implant%') AND
         i.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- vitrectomy_excl (%vitrectomy& before baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgery s
    ON p.PatientID = s.PatientID AND
       p.EyeCode = s.EyeCode
    SET p.vitrectomy_excl =
    CASE
    WHEN s.ProcedureDesc LIKE '%vitrectomy%' AND
         s.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;
  
  /*
  -- diabetic_retinopathy_excl (presence of ≥ 1 grade-diabetic reitnopathy as per ETDRS, NSC, or International)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCDRGrading d
    ON p.PatientID = d.PatientID AND
       p.EyeCode = d.EyeCode
    SET p.diabetic_retinopathy_excl =
    CASE
    WHEN d.DRGradeDesc LIKE '%PDR%' OR
         d.DRGradeDesc LIKE 'Scatter (PRP) Retinal Laser Scars Visible' OR 
         d.DRGradeDesc IN ('R1', 'R2', 'R3', 'M1', 'P') OR
         d.DRGradeDesc LIKE 'Proliferative DR' AND
         d.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- rvo_excl (retinal vein occlusion before baseline (inclusive of central, branch, hemi-branch, & macular-branch))
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgeryIndications i
    ON p.PatientID = i.PatientID AND
       p.EyeCode = i.EyeCode
    SET p.rvo_excl =
    CASE
    WHEN i.IndicationDesc LIKE '%retinal vein occlusion%' AND
         i.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- glaucoma_excl (trabeculectomy before baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgery s
    ON p.PatientID = s.PatientID AND
       p.EyeCode = s.EyeCode
    SET p.glaucoma_excl =
    CASE
    WHEN s.ProcedureDesc LIKE '%trabeculectomy%' AND
         s.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

  /*
  -- corneal_transplant_excl
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCSurgery s
    ON p.PatientID = s.PatientID AND
       p.EyeCode = s.EyeCode
    SET p.corneal_transplant_excl =
    CASE
    WHEN s.ProcedureDesc LIKE '%keratoplasty%' AND
         s.EncounterDate <= p.baseline_eylea_date
    THEN 1
    ELSE 0
    END;

/*
-- sub_mac_surg_excl (any surgery for indications associated with AMD phenotype)
*/



/*
-- Export to .csv
*/

SELECT *
FROM amd_synthetic_eylea_arm_study_table;