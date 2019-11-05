-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
-- Script to create tables: nvAMDSurgeryIndications; nvAMDInjections; and nvAMDVisualAcuity

-- retrieve all eyes that have surgery indications for nvAMD ehr phenotypes
DROP TABLE IF EXISTS nvAMDSurgeryIndications;

CREATE TABLE nvAMDSurgeryIndications AS
SELECT * 
FROM ETCSurgeryIndications 
WHERE 
      (IndicationDesc LIKE 'neovascular AMD %') 
OR 
      IndicationDesc IN ('wet age-related macular degeneration', 'age-related macular degeneration', 'suspected neovascular AMD');

CREATE INDEX idx_nvAMDSurgeryIndications_pt_st_e ON nvAMDSurgeryIndications (`PatientID`, `SiteID`, `EyeCode`);

-- retrieve all episodes for nvAMD cohort wherein avastin, lucentis or eylea was administered
DROP TABLE IF EXISTS nvAMDInjections;

CREATE TABLE nvAMDInjections AS
SELECT i.* 
FROM nvAMDSurgeryIndications s 
JOIN ETCInjections i 
ON s.PatientID = i.PatientID AND s.EyeCode = i.EyeCode AND s.SiteID = i.SiteID AND s.EncounterDate = i.EncounterDate 
WHERE InjectedDrugDesc IN ("Avastin 1.25 mg/0.05 ml", "Avastin 2 mg/0.08 ml", "Avastin 2.5 mg/0.10 ml", "Eylea 2 mg/0.05ml (aflibercept)", "Lucentis 0.3 mg", "Lucentis 0.5 mg");

CREATE INDEX idx_nvAMDInjections_pt_st_e ON nvAMDInjections (`PatientID`, `SiteID`, `EyeCode`);
CREATE INDEX idx_nvAMDInjections_pt_e ON nvAMDInjections (`PatientID`, `SiteID`);

-- retrieve all va measurements for nvAMD cohort
DROP TABLE IF EXISTS nvAMDVisualAcuity;

CREATE TABLE nvAMDVisualAcuity AS
SELECT v.*
FROM VA_simple_meta v 
JOIN 10yearAMDPatientMeta p 
ON v.PatientID = p.PatientID AND v.SiteID = p.SiteID AND v.Eye = p.Eye
JOIN nvAMDInjections i
ON v.PatientID = i.PatientID AND v.SiteID = i.SiteID AND v.Eye = i.EyeCode;

CREATE INDEX idx_nvAMDVisualAcuity_pt_st_e ON nvAMDVisualAcuity (`PatientID`, `SiteID`, `Eye`);
CREATE INDEX idx_nvAMDVisualAcuity_pt_st_e_d ON nvAMDVisualAcuity (`SiteID`,`PatientID`,`Eye`, `Date`);
CREATE INDEX idx_nvAMDVisualAcuity_st_ei ON nvAMDVisualAcuity (`SiteID`, `EncounterID`);
CREATE INDEX idx_nvAMDVisualAcuity_pt_e ON nvAMDVisualAcuity (`PatientID`, `Eye`);

DELETE FROM 10yearAMDVA_simple_meta WHERE ETDRS = -10000;