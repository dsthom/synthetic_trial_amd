-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
-- not advisable to bin va measurements in allignment with abc trial, but keep the code nevertheless

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

-- StudyExit (date as the date of va measurement cloest to day 378 (54 weeks * 7 days))
UPDATE AMDSyntheticEyleaArmMeta p
SET StudyExit = (
  SELECT MIN(v.Date)
  FROM nvAMDVisualAcuity v
  WHERE p.PatientID = v.PatientID AND p.Eye = v.Eye AND p.SiteID = v.SiteID AND
  (DATEDIFF(v.Date, p.BaselineDate)) BETWEEN 371 AND 377 AND p.va_54 = v.ETDRS
);
