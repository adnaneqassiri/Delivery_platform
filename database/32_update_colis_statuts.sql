--------------------------------------------------
-- UPDATE: Colis status values
-- Change from: ENREGISTRE, EN_COURS, LIVRE, ANNULE, RECUPEREE
-- To: ENREGISTREE, EN_COURS, RECEPTIONNEE, ENVOYEE, ANNULEE, RECUPEREE
--------------------------------------------------

PROMPT ========================================
PROMPT Step 1: Find and drop existing constraint
PROMPT ========================================

-- Find constraint name dynamically
DECLARE
  v_constraint_name VARCHAR2(100);
BEGIN
  SELECT constraint_name
  INTO v_constraint_name
  FROM user_constraints
  WHERE table_name = 'COLIS'
    AND constraint_type = 'C'
    AND search_condition_vc LIKE '%statut%'
  FETCH FIRST 1 ROWS ONLY;

  EXECUTE IMMEDIATE 'ALTER TABLE colis DROP CONSTRAINT ' || v_constraint_name;
  DBMS_OUTPUT.PUT_LINE('Dropped constraint: ' || v_constraint_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No statut constraint found, skipping drop');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error dropping constraint: ' || SQLERRM);
END;
/

PROMPT 
PROMPT ========================================
PROMPT Step 2: Update existing colis statuses to new values
PROMPT ========================================

-- Map old statuses to new statuses
UPDATE colis SET statut = 'ENREGISTREE' WHERE statut = 'ENREGISTRE';
-- Note: We need to map LIVRE to ENVOYEE, but this should be done carefully
-- For now, we'll map LIVRE to ENVOYEE (colis that have been sent/delivered)
UPDATE colis SET statut = 'ENVOYEE' WHERE statut = 'LIVRE';
UPDATE colis SET statut = 'ANNULEE' WHERE statut = 'ANNULE';
-- EN_COURS stays the same
-- RECUPEREE stays the same
-- For RECEPTIONNEE: This is a new status, so existing records with status ENVOYEE 
-- that are at destination should be marked as RECEPTIONNEE by the application logic

PROMPT Existing colis statuses updated.

PROMPT 
PROMPT ========================================
PROMPT Step 3: Recreate constraint with new status values
PROMPT ========================================

ALTER TABLE colis ADD CONSTRAINT chk_colis_statut 
  CHECK (statut IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE'));

PROMPT Constraint recreated with new status values.

PROMPT 
PROMPT ========================================
PROMPT Step 4: Update historique_statut_colis
PROMPT ========================================

-- Update historical records as well
UPDATE historique_statut_colis SET statut_avant = 'ENREGISTREE' WHERE statut_avant = 'ENREGISTRE';
UPDATE historique_statut_colis SET statut_avant = 'ENVOYEE' WHERE statut_avant = 'LIVRE';
UPDATE historique_statut_colis SET statut_avant = 'ANNULEE' WHERE statut_avant = 'ANNULE';

UPDATE historique_statut_colis SET statut_apres = 'ENREGISTREE' WHERE statut_apres = 'ENREGISTRE';
UPDATE historique_statut_colis SET statut_apres = 'ENVOYEE' WHERE statut_apres = 'LIVRE';
UPDATE historique_statut_colis SET statut_apres = 'ANNULEE' WHERE statut_apres = 'ANNULE';

PROMPT Historical records updated.

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Update completed!
PROMPT ========================================
PROMPT 
PROMPT New status values: ENREGISTREE, EN_COURS, RECEPTIONNEE, ENVOYEE, ANNULEE, RECUPEREE
PROMPT 
PROMPT Note: You may need to update triggers and package procedures to use the new status values.
