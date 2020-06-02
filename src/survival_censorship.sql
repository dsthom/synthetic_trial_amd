-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)

/*
-- create table create table of va readings in longforcm for abc avastin arm and all eligible eylea synthetifc controls
*/

DROP TABLE IF EXISTS syn_avastin_eylea_va_longform;

CREATE TABLE syn_avastin_eylea_va_longform AS

SELECT *
FROM abc_va_longform
WHERE treatment = 'avastin'

UNION

SELECT s.patient_eye AS id, 
       s.treatment, 
       CEILING(DATEDIFF(v.EncounterDate, s.baseline_eylea_date) / 7) AS week,
       MAX(v.max_etdrs) as etdrs
FROM amd_synthetic_eylea_arm_study_table s
LEFT JOIN nvAMD_visual_acuity v
USING(patient_eye)
WHERE s.eligibility = 1 AND
      CEILING(DATEDIFF(v.EncounterDate, s.baseline_eylea_date) / 7) BETWEEN 0 AND 54 AND
      v.EncounterDate > s.baseline_eylea_date
GROUP BY id, v.EncounterDate;
      
/*
-- impute negative integers to 0 or as NULL if 100000
*/

UPDATE syn_avastin_eylea_va_longform
SET etdrs = 
  CASE
  WHEN etdrs = -10000 THEN NULL
  WHEN etdrs < 0 THEN 0
  ELSE etdrs
  END;
      
/*
--
*/

DROP TABLE IF EXISTS syn_avastin_eylea_censorship;

CREATE TABLE syn_avastin_eylea_censorship AS
  
  SELECT id,
         treatment
  FROM syn_avastin_eylea_va_longform
  GROUP BY id;
  
ALTER TABLE syn_avastin_eylea_censorship
  ADD COLUMN baseline_read INT(3) DEFAULT NULL,
  ADD COLUMN greater_or_eq_15 INT(2) DEFAULT NULL,
  ADD COLUMN greater_or_eq_10 INT(2) DEFAULT NULL,
  ADD COLUMN greater_or_eq_neg_15 INT(2) DEFAULT NULL,
  ADD COLUMN last_va_week INT(2) DEFAULT NULL;

/*
-- baseline_read
*/

UPDATE syn_avastin_eylea_censorship s 
LEFT JOIN syn_avastin_eylea_va_longform v
USING(id)
SET s.baseline_read = v.etdrs
WHERE v.week = 0 AND 
      s.treatment = 'avastin';

UPDATE syn_avastin_eylea_censorship c 
LEFT JOIN amd_synthetic_eylea_arm_study_table s
ON c.id = s.patient_eye
SET c.baseline_read = s.baseline_va;

/*
-- greater_or_eq_15
*/

UPDATE syn_avastin_eylea_censorship s
SET greater_or_eq_15 = (
  SELECT MIN(week)
  FROM syn_avastin_eylea_va_longform v
  WHERE v.etdrs - s.baseline_read >= 15 AND
        s.id = v.id
);

/*
-- greater_or_eq_10
*/

UPDATE syn_avastin_eylea_censorship s
SET greater_or_eq_10 = (
  SELECT MIN(week)
  FROM syn_avastin_eylea_va_longform v
  WHERE v.etdrs - s.baseline_read >= 10 AND
        s.id = v.id
);

/*
-- greater_or_eq_neg_15
*/

UPDATE syn_avastin_eylea_censorship s
SET greater_or_eq_neg_15 = (
  SELECT MIN(week)
  FROM syn_avastin_eylea_va_longform v
  WHERE v.etdrs - s.baseline_read < -15 AND
        s.id = v.id
);

/*
-- last_va_date
*/

UPDATE syn_avastin_eylea_censorship s
SET last_va_week = (
  SELECT MAX(week)
  FROM syn_avastin_eylea_va_longform v
  WHERE s.id = v.id
);
