-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)
/* 
Script to create & populate the study table: amd_synthetic_eylea_arm_study_table having run 
amd_irf_srf_large_tables.sql
*/ 
 
/*  
-- create table to be used for this study only
*/
  
  DROP TABLE IF EXISTS amd_synthetic_eylea_arm_study_table;

-- 2020-01-06 14:36:12.3120

  
  CREATE TABLE amd_synthetic_eylea_arm_study_table AS
    SELECT PatientID, EyeCode, SiteID
    FROM nvAMD_surgery_indications
    GROUP BY PatientID, EyeCode;

-- 2020-01-06 14:36:17.3600

    
  CREATE INDEX idx_amd_synthetic_eylea_arm_study_table_pt_e ON amd_synthetic_eylea_arm_study_table (`PatientID`, `EyeCode`);

-- 2020-01-06 14:36:18.6880

  CREATE INDEX idx_amd_synthetic_eylea_arm_study_table_pt ON amd_synthetic_eylea_arm_study_table (`PatientID`);

-- 2020-01-06 14:36:20.6730

  
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
    ADD COLUMN eylea_start_date DATE DEFAULT NULL,
    ADD COLUMN avastin_start_date DATE DEFAULT NULL,
    ADD COLUMN lucentis_start_date DATE DEFAULT NULL,
    ADD COLUMN avastin_lucentis_before_eylea INT(11) DEFAULT NULL,
    ADD COLUMN affected_eyes INT(11) DEFAULT NULL,
    ADD COLUMN index_eye INT(11) DEFAULT NULL,
    ADD COLUMN index_date DATE DEFAULT NULL,
    ADD COLUMN age_at_baseline INT(11) DEFAULT NULL,
    ADD COLUMN injection_count INT(11) DEFAULT NULL,
    ADD COLUMN no_eylea_excl INT(11) DEFAULT NULL,
    ADD COLUMN switch_excl INT(11) DEFAULT NULL,
    ADD COLUMN radio_thermo_excl INT(11) DEFAULT NULL,
    ADD COLUMN verteporfin_thermo_excl INT(11) DEFAULT NULL,
    ADD COLUMN clinical_trial_excl INT(11) DEFAULT NULL,
    ADD COLUMN intravitreal_excl INT(11) DEFAULT NULL,
    ADD COLUMN vitrectomy_excl INT(11) DEFAULT NULL,
    ADD COLUMN diabetic_retinopathy_excl INT(11) DEFAULT NULL,
    ADD COLUMN rvo_excl INT(11) DEFAULT NULL,
    ADD COLUMN glaucoma_excl INT(11) DEFAULT NULL,
    ADD COLUMN corneal_transplant_excl INT(11) DEFAULT NULL,
    ADD COLUMN sub_mac_surg_excl INT(11) DEFAULT NULL;

-- 2020-01-06 14:36:24.8700


  /*
  patient_eye
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET patient_eye = CONCAT(PatientID, '-', EyeCode);

-- 2020-01-06 14:36:28.9440


  /*
  gender
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table s
  JOIN ETCPatientDetails p
  ON s.PatientID = p.PatientID
  SET s.gender = p.Gender;

-- 2020-01-06 14:36:33.3030

  
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

-- 2020-01-06 14:36:39.6140

  
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

-- 2020-01-06 14:38:06.8040

	
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

-- 2020-01-06 14:38:32.6660

  
  /*
  -- estimated_study_exit (the date 378 days (54 weeks * 7 days) onwards from baseline)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET estimated_study_exit = DATE_ADD(eylea_start_date, INTERVAL 378 DAY);

-- 2020-01-06 14:38:32.8050

  
  /*
  -- study_exit (date of va measurement closest---but prior---to estimated_study_exit)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  SET study_exit = (
    SELECT MAX(v.EncounterDate)
    FROM nvAMD_visual_acuity v
    WHERE p.PatientID = v.PatientID AND 
          p.EyeCode = v.EyeCode AND 
          v.EncounterDate > p.eylea_start_date AND
          v.EncounterDate <= p.estimated_study_exit
    LIMIT 1
  );

-- 2020-01-06 14:38:32.8850

  
  /*
  -- eylea_start_date
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  SET p.eylea_start_date = (
  SELECT MIN(i.EncounterDate)
  FROM nvAMD_injections i
  WHERE p.PatientID = i.PatientID AND 
        p.EyeCode = i.EyeCode AND
        i.AntiVEGFInjection = 1 AND
        i.InjectedDrugDesc = "Eylea 2 mg/0.05ml (aflibercept)"
  );

-- 2020-01-06 14:38:39.7810

  
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

-- 2020-01-06 14:38:48.3730

  
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

-- 2020-01-06 14:38:59.5390

  
  /*
  -- avastin_lucentis_before_eylea (1 if Eylea is first VEGF inhibitor administered)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET avastin_lucentis_before_eylea = CASE 
                       WHEN avastin_start_date <= eylea_start_date  OR
                            lucentis_start_date <= eylea_start_date
                       THEN 1
                       ELSE 0
                       END;

-- 2020-01-06 14:39:04.2250

  
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

-- 2020-01-06 14:39:08.9100

  
  /*
  -- index_eye (if > 1 EyeCode affected, assign the EyeCode diagnosed earliest & then random EyeCode if tied)
  */
  
  -- if one EyeCode affected, assign only as index
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET index_eye = 1
  WHERE affected_eyes = 1;

-- 2020-01-06 14:39:12.3620

  
  -- if two eyes, assign earliest diagnosed
  
  UPDATE amd_synthetic_eylea_arm_study_table p1,
  	(SELECT MIN(eylea_start_date) AS index_date, PatientID, EyeCode
  	FROM amd_synthetic_eylea_arm_study_table
  	WHERE index_eye IS NULL
  	GROUP BY PatientID
  	HAVING COUNT(DISTINCT eylea_start_date) > 1) p2
  SET index_eye = 1
  WHERE p1.PatientID = p2.PatientID AND p1.eylea_start_date = p2.index_date;

-- 2020-01-06 14:39:12.4870

  
  -- if two eyes diagnosed on same day, assign index at random
  DROP TEMPORARY TABLE IF EXISTS SYN_randomly_selected_eyes;

-- 2020-01-06 14:39:12.5790

  
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

-- 2020-01-06 14:39:14.4090

	
	UPDATE amd_synthetic_eylea_arm_study_table s
	JOIN SYN_randomly_selected_eyes r
	ON s.patient_eye = r.patient_eye
	SET s.index_eye = 1;

-- 2020-01-06 14:49:26.1080

	
	UPDATE amd_synthetic_eylea_arm_study_table
	SET index_eye = 0
	WHERE index_eye IS NULL;

-- 2020-01-06 14:49:28.9930

  
  -- check that all patients have 1 index EyeCode assigned
  
  SELECT COUNT(*)
  FROM amd_synthetic_eylea_arm_study_table
  GROUP BY PatientID
  HAVING COUNT(index_eye) < 1;

-- 2020-01-06 14:49:29.2540

  
  /*
  -- index_date
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p1,
    (SELECT eylea_start_date AS index_date, PatientID
    FROM amd_synthetic_eylea_arm_study_table
    WHERE index_eye = 1
    ) p2
  SET p1.index_date = p2.index_date
  WHERE p1.PatientID = p2.PatientID;

-- 2020-01-06 14:49:29.4090

  
  /*
  -- age_at_baseline (years between perturbed date of bith and eylea_start_date)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  JOIN ETCPatientDetails d
  ON p.PatientID = d.PatientID 
  SET age_at_baseline = DATEDIFF(p.eylea_start_date, d.PerturbedDateofBirth) / 365.25;

-- 2020-01-06 14:49:29.4860

  
  /*
  -- injection_count (number of Eylea injections recieved during study period)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table p
  SET injection_count = (
    SELECT COUNT(DISTINCT i.EncounterDate)
    FROM nvAMD_injections i
    WHERE p.PatientID = i.PatientID AND 
          p.EyeCode = i.EyeCode AND 
          i.EncounterDate >= p.eylea_start_date AND 
          i.EncounterDate <= p.study_exit AND
          i.InjectedDrugDesc = 'Eylea 2 mg/0.05ml (aflibercept)'
  );

-- 2020-01-06 14:49:29.6310

  
  /*
  no_eylea_excl
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table 
  SET no_eylea_excl =  CASE
                       WHEN  eylea_start_date IS NULL
                       THEN 1
                       ELSE 0
                       END;

-- 2020-01-06 14:49:34.5100

  
  /*
  -- switch_excl (1 if avastin_start_date OR lucentis_start_date <= study_exit)
  */
  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET switch_excl = CASE 
                    WHEN avastin_start_date >= eylea_start_date AND avastin_start_date < study_exit OR
                         lucentis_start_date >= eylea_start_date AND lucentis_start_date < study_exit
                    THEN 1
                    ELSE 0
                    END;

-- 2020-01-06 14:49:34.7010

  
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
         s.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:49:34.8650

    
  UPDATE amd_synthetic_eylea_arm_study_table
  SET radio_thermo_excl = 0
  WHERE radio_thermo_excl IS NULL;

-- 2020-01-06 14:49:38.5240

  
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

-- 2020-01-06 14:49:47.4610

  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET verteporfin_thermo_excl = 0
  WHERE verteporfin_thermo_excl IS NULL;

-- 2020-01-06 14:49:48.0240

  
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
         i.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:49:48.1400

  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET clinical_trial_excl = 0
  WHERE clinical_trial_excl IS NULL;

-- 2020-01-06 14:49:54.2870

  
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
         i.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:49:54.4650

    
  UPDATE amd_synthetic_eylea_arm_study_table
  SET intravitreal_excl = 0
  WHERE intravitreal_excl IS NULL;

-- 2020-01-06 14:50:02.0320

  
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
         s.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:50:02.2410

  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET vitrectomy_excl = 0
  WHERE vitrectomy_excl IS NULL;

-- 2020-01-06 14:50:09.6930
  
  
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
         d.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:50:09.8340

  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET diabetic_retinopathy_excl = 0
  WHERE diabetic_retinopathy_excl IS NULL;

-- 2020-01-06 14:50:16.6790
  
  
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
         i.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:50:16.7980

    
  UPDATE amd_synthetic_eylea_arm_study_table
  SET rvo_excl = 0
  WHERE rvo_excl IS NULL;

-- 2020-01-06 14:50:23.3140
 
  
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
         s.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:50:23.4020

  
  UPDATE amd_synthetic_eylea_arm_study_table
  SET glaucoma_excl = 0
  WHERE glaucoma_excl IS NULL;

-- 2020-01-06 14:50:29.3070

  
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
         s.EncounterDate <= p.eylea_start_date
    THEN 1
    ELSE 0
    END;

-- 2020-01-06 14:50:29.4080

    
  UPDATE amd_synthetic_eylea_arm_study_table
  SET corneal_transplant_excl = 0
  WHERE corneal_transplant_excl IS NULL;

-- 2020-01-06 14:50:35.4300


/*
-- sub_mac_surg_excl (any surgery for indications associated with AMD phenotype)
*/



/*
-- Export to .csv
*/

SELECT *
FROM amd_synthetic_eylea_arm_study_table;