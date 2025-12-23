--------------------------------------------------
-- FIX: Colis status constraint violation
-- This script identifies and fixes any colis with invalid status values
--------------------------------------------------

PROMPT ========================================
PROMPT Step 1: Check current status values in colis table
PROMPT ========================================

SELECT statut, COUNT(*) as count
FROM colis
GROUP BY statut
ORDER BY statut;

PROMPT 
PROMPT ========================================
PROMPT Step 2: Check for NULL or invalid status values
PROMPT ========================================

SELECT COUNT(*) as invalid_count
FROM colis
WHERE statut IS NULL 
   OR statut NOT IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE');

-- Show which rows have invalid statuses
SELECT id_colis, statut
FROM colis
WHERE statut IS NULL 
   OR statut NOT IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE');

PROMPT 
PROMPT ========================================
PROMPT Step 3: Fix any remaining invalid statuses
PROMPT ========================================

-- Fix any remaining old status values
UPDATE colis SET statut = 'ENREGISTREE' WHERE statut = 'ENREGISTRE';
PROMPT Updated ENREGISTRE -> ENREGISTREE: &SQL%ROWCOUNT rows

UPDATE colis SET statut = 'ENVOYEE' WHERE statut = 'LIVRE';
PROMPT Updated LIVRE -> ENVOYEE: &SQL%ROWCOUNT rows

UPDATE colis SET statut = 'ANNULEE' WHERE statut = 'ANNULE';
PROMPT Updated ANNULE -> ANNULEE: &SQL%ROWCOUNT rows

-- If there are any NULL statuses, set them to ENREGISTREE (default)
UPDATE colis SET statut = 'ENREGISTREE' WHERE statut IS NULL;
PROMPT Updated NULL -> ENREGISTREE: &SQL%ROWCOUNT rows

-- Check for any other unexpected values
PROMPT 
PROMPT Checking for any other unexpected status values...
SELECT DISTINCT statut
FROM colis
WHERE statut NOT IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE');

PROMPT 
PROMPT ========================================
PROMPT Step 4: Verify all statuses are valid
PROMPT ========================================

SELECT statut, COUNT(*) as count
FROM colis
GROUP BY statut
ORDER BY statut;

-- Final check: count invalid statuses (should be 0)
SELECT COUNT(*) as remaining_invalid
FROM colis
WHERE statut IS NULL 
   OR statut NOT IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE');

PROMPT 
PROMPT ========================================
PROMPT Step 5: Drop and recreate constraint
PROMPT ========================================

-- Drop constraint if it exists (in case it was partially created)
BEGIN
  FOR r IN (SELECT constraint_name FROM user_constraints WHERE table_name = 'COLIS' AND constraint_name = 'CHK_COLIS_STATUT') LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE colis DROP CONSTRAINT ' || r.constraint_name;
    DBMS_OUTPUT.PUT_LINE('Dropped existing constraint: ' || r.constraint_name);
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('No existing constraint to drop or error: ' || SQLERRM);
END;
/

-- Now create the constraint
ALTER TABLE colis ADD CONSTRAINT chk_colis_statut 
  CHECK (statut IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE'));

PROMPT Constraint created successfully!

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Fix completed!
PROMPT ========================================
PROMPT All colis now have valid status values and the constraint is active.
PROMPT 
PROMPT If you still see errors, check the output above for any unexpected status values
PROMPT and update them manually before running this script again.
