-- !preview conn=DBI::dbConnect(RMySQL::MySQL(), user = "admin", password = "password", dbname = "NOVA5", host = "127.0.0.1", port = 9999)

/* 
Script to create & populate the study table: amd_synthetic_time_to_event_study_table having run 
amd_irf_srf_large_tables.sql, synthetic_eylea_arm_study_table.sql, and exact_matching_eylea.Rmd.

The script creates three temporary tables (I) >= 15 letters gain; II) >= 10 letters gain); 
III) > 15 letters loss.
*/ 
 
/*
temp_15_gain_exact
*/

DROP TEMPORARY TABLE IF EXISTS temp_15_gain_exact;

CREATE TEMPORARY TABLE temp_15_gain_exact AS
  SELECT id
  FROM eylea_exact_pairs_long
  ORDER BY cohort;

ALTER TABLE temp_15_gain_exact
  ADD COLUMN drug VARCHAR(255) DEFAULT NULL,
  ADD COLUMN event VARCHAR(255) DEFAULT NULL,
  ADD COLUMN baseline_etdrs INT(2) DEFAULT NULL,
  ADD COLUMN outcome INT(1) DEFAULT 0,
  ADD COLUMN outcome_week INT(2) DEFAULT NULL,
  ADD COLUMN last_va_week INT(2) DEFAULT NULL,
  ADD COLUMN week_exit INT(2) DEFAULT NULL;

-- drug

UPDATE temp_15_gain_exact a
JOIN eylea_exact_pairs_long b
USING(id)
SET a.drug =
  CASE
    WHEN b.cohort = "abc_id" THEN "avastin"
    WHEN b.cohort = "ehr_id" THEN "eylea"
    ELSE a.drug
  END;

-- event

UPDATE temp_15_gain_exact
SET event = "15_letters_gain";

-- baseline_etdrs

UPDATE temp_15_gain_exact a
SET baseline_etdrs = (
  SELECT etdrs
  FROM eylea_exact_va_long  b
  WHERE b.week = 0 AND
        b.id = a.id
);

-- outcome

UPDATE temp_15_gain_exact a
JOIN eylea_exact_va_long b
USING(id)
SET a.outcome = 1
WHERE (b.etdrs - a.baseline_etdrs) >= 15;

-- outcome_week

UPDATE temp_15_gain_exact a
SET outcome_week = (
  SELECT MIN(week)
  FROM eylea_exact_va_long b
  WHERE (b.etdrs - a.baseline_etdrs) >= 15 AND
         a.id = b.id
);

-- last_va_week

UPDATE temp_15_gain_exact a
SET last_va_week = (
  SELECT MAX(week)
  FROM eylea_exact_va_long b
  WHERE a.id = b.id
);

-- week_exit

UPDATE temp_15_gain_exact
SET week_exit = 
  CASE
    WHEN outcome_week IS NOT NULL THEN outcome_week
    WHEN outcome_week IS NULL THEN last_va_week
    ELSE week_exit
    END;

/*
temp_10_gain_exact
*/

DROP TEMPORARY TABLE IF EXISTS temp_10_gain_exact;

CREATE TEMPORARY TABLE temp_10_gain_exact AS
  SELECT id
  FROM eylea_exact_pairs_long
  ORDER BY cohort;

ALTER TABLE temp_10_gain_exact
  ADD COLUMN drug VARCHAR(255) DEFAULT NULL,
  ADD COLUMN event VARCHAR(255) DEFAULT NULL,
  ADD COLUMN baseline_etdrs INT(2) DEFAULT NULL,
  ADD COLUMN outcome INT(1) DEFAULT 0,
  ADD COLUMN outcome_week INT(2) DEFAULT NULL,
  ADD COLUMN last_va_week INT(2) DEFAULT NULL,
  ADD COLUMN week_exit INT(2) DEFAULT NULL;

-- drug

UPDATE temp_10_gain_exact a
JOIN eylea_exact_pairs_long b
USING(id)
SET a.drug =
  CASE
    WHEN b.cohort = "abc_id" THEN "avastin"
    WHEN b.cohort = "ehr_id" THEN "eylea"
    ELSE a.drug
  END;

-- event

UPDATE temp_10_gain_exact
SET event = "10_letters_gain";

-- baseline_etdrs

UPDATE temp_10_gain_exact a
SET baseline_etdrs = (
  SELECT etdrs
  FROM eylea_exact_va_long  b
  WHERE b.week = 0 AND
        b.id = a.id
);

-- outcome

UPDATE temp_10_gain_exact a
JOIN eylea_exact_va_long b
USING(id)
SET a.outcome = 1
WHERE (b.etdrs - a.baseline_etdrs) >= 10;

-- outcome_week

UPDATE temp_10_gain_exact a
SET outcome_week = (
  SELECT MIN(week)
  FROM eylea_exact_va_long b
  WHERE (b.etdrs - a.baseline_etdrs) >= 10 AND
         a.id = b.id
);

-- last_va_week

UPDATE temp_10_gain_exact a
SET last_va_week = (
  SELECT MAX(week)
  FROM eylea_exact_va_long b
  WHERE a.id = b.id
);

-- week_exit

UPDATE temp_10_gain_exact
SET week_exit = 
  CASE
    WHEN outcome_week IS NOT NULL THEN outcome_week
    WHEN outcome_week IS NULL THEN last_va_week
    ELSE week_exit
    END;


/*
temp_15_loss_exact
*/

DROP TEMPORARY TABLE IF EXISTS temp_15_loss_exact;

CREATE TEMPORARY TABLE temp_15_loss_exact AS
  SELECT id
  FROM eylea_exact_pairs_long
  ORDER BY cohort;

ALTER TABLE temp_15_loss_exact
  ADD COLUMN drug VARCHAR(255) DEFAULT NULL,
  ADD COLUMN event VARCHAR(255) DEFAULT NULL,
  ADD COLUMN baseline_etdrs INT(2) DEFAULT NULL,
  ADD COLUMN outcome INT(1) DEFAULT 0,
  ADD COLUMN outcome_week INT(2) DEFAULT NULL,
  ADD COLUMN last_va_week INT(2) DEFAULT NULL,
  ADD COLUMN week_exit INT(2) DEFAULT NULL;

-- drug

UPDATE temp_15_loss_exact a
JOIN eylea_exact_pairs_long b
USING(id)
SET a.drug =
  CASE
    WHEN b.cohort = "abc_id" THEN "avastin"
    WHEN b.cohort = "ehr_id" THEN "eylea"
    ELSE a.drug
  END;

-- event

UPDATE temp_15_loss_exact
SET event = "15_letters_lost";

-- baseline_etdrs

UPDATE temp_15_loss_exact a
SET baseline_etdrs = (
  SELECT etdrs
  FROM eylea_exact_va_long  b
  WHERE b.week = 0 AND
        b.id = a.id
);

-- outcome

UPDATE temp_15_loss_exact a
JOIN eylea_exact_va_long b
USING(id)
SET a.outcome = 1
WHERE (a.baseline_etdrs - b.etdrs) > 15;

-- outcome_week

UPDATE temp_15_loss_exact a
SET outcome_week = (
  SELECT MIN(week)
  FROM eylea_exact_va_long b
  WHERE (a.baseline_etdrs - b.etdrs) > 15 AND
         a.id = b.id
);

-- last_va_week

UPDATE temp_15_loss_exact a
SET last_va_week = (
  SELECT MAX(week)
  FROM eylea_exact_va_long b
  WHERE a.id = b.id
);

-- week_exit

UPDATE temp_15_loss_exact
SET week_exit = 
  CASE
    WHEN outcome_week IS NOT NULL THEN outcome_week
    WHEN outcome_week IS NULL THEN last_va_week
    ELSE week_exit
    END;
/*

*/

DROP TABLE IF EXISTS synthetic_eylea_exact_survival;

CREATE TABLE synthetic_eylea_exact_survival AS
  (SELECT * FROM temp_15_gain_exact)
  UNION
  (SELECT * FROM temp_10_gain_exact)
  UNION
  (SELECT * FROM temp_15_loss_exact);

/* 
LUCENTIS
*/

