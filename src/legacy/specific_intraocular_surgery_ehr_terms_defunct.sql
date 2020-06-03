-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
/*
below ABC criteria grouped under intraocular_surg_excl. Code is here for reference.
*/

  ADD COLUMN intravitreal_excl INT(1) DEFAULT 0,
  ADD COLUMN vitrectomy_excl INT(1) DEFAULT 0,
  ADD COLUMN rvo_excl INT(1) DEFAULT 0,
  ADD COLUMN trabeculectomy_excl INT(1) DEFAULT 0,
  ADD COLUMN sub_mac_surg_excl INT(1) DEFAULT 0,
  ADD COLUMN haemorrhage_excl INT(1) DEFAULT 0,
  ADD COLUMN subfoveal_excl INT(1) DEFAULT 0,
  ADD COLUMN tear_excl INT(1) DEFAULT 0,
  ADD COLUMN vitreous_haemorrhage_excl INT(1) DEFAULT 0,
  ADD COLUMN rheg_hole_excl INT(1) DEFAULT 0,
  ADD COLUMN uveitis_excl INT(1) DEFAULT 0,
  ADD COLUMN glaucoma_excl INT(1) DEFAULT 0,

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
-- glaucoma_excl
*/
