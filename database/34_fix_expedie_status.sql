--------------------------------------------------
-- FIX: EXPEDIE status -> map to valid status
-- EXPEDIE should be mapped to ENVOYEE (colis that have been sent)
--------------------------------------------------

PROMPT ========================================
PROMPT Fixing EXPEDIE status values
PROMPT ========================================

-- Map EXPEDIE to ENVOYEE (colis that have been sent/dispatched)
UPDATE colis SET statut = 'ENVOYEE' WHERE statut = 'EXPEDIE';
PROMPT Updated EXPEDIE -> ENVOYEE: &SQL%ROWCOUNT rows

PROMPT 
PROMPT ========================================
PROMPT Verify all statuses are now valid
PROMPT ========================================

SELECT statut, COUNT(*) as count
FROM colis
GROUP BY statut
ORDER BY statut;

-- Check for any remaining invalid statuses
SELECT COUNT(*) as remaining_invalid
FROM colis
WHERE statut IS NULL 
   OR statut NOT IN ('ENREGISTREE','EN_COURS','RECEPTIONNEE','ENVOYEE','ANNULEE','RECUPEREE');

PROMPT 
PROMPT ========================================
PROMPT Drop and recreate constraint
PROMPT ========================================

-- Drop constraint if it exists
BEGIN
  FOR r IN (SELECT constraint_name FROM user_constraints WHERE table_name = 'COLIS' AND constraint_name = 'CHK_COLIS_STATUT') LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE colis DROP CONSTRAINT ' || r.constraint_name;
    DBMS_OUTPUT.PUT_LINE('Dropped existing constraint: ' || r.constraint_name);
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Note: ' || SQLERRM);
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
PROMPT All EXPEDIE statuses have been mapped to ENVOYEE
PROMPT and the constraint is now active.


