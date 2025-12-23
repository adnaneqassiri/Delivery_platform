--------------------------------------------------
-- FIX: Trigger syntax error
-- The DECLARE block inside EXCEPTION is causing the issue
-- We need to create a procedure for the autonomous transaction part
--------------------------------------------------

-- First, create a helper procedure for creating livraisons
CREATE OR REPLACE PROCEDURE p_create_livraison_if_needed(
  p_id_entrepot_source NUMBER,
  p_id_entrepot_destination NUMBER,
  p_id_livraison OUT NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_exists NUMBER;
BEGIN
  -- Check if a CREEE livraison already exists
  SELECT COUNT(*)
  INTO v_exists
  FROM livraisons
  WHERE id_entrepot_source = p_id_entrepot_source
    AND id_entrepot_destination = p_id_entrepot_destination
    AND statut = 'CREEE';

  IF v_exists > 0 THEN
    -- Get the first (oldest) one
    SELECT id_livraison
    INTO p_id_livraison
    FROM livraisons
    WHERE id_entrepot_source = p_id_entrepot_source
      AND id_entrepot_destination = p_id_entrepot_destination
      AND statut = 'CREEE'
    ORDER BY id_livraison
    FETCH FIRST 1 ROWS ONLY;
  ELSE
    -- Create a new one
    INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
    VALUES (p_id_entrepot_source, p_id_entrepot_destination, 'CREEE', SYSTIMESTAMP)
    RETURNING id_livraison INTO p_id_livraison;
    COMMIT;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- If creation fails, try to get existing one
    BEGIN
      SELECT id_livraison
      INTO p_id_livraison
      FROM livraisons
      WHERE id_entrepot_source = p_id_entrepot_source
        AND id_entrepot_destination = p_id_entrepot_destination
        AND statut = 'CREEE'
      ORDER BY id_livraison
      FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_id_livraison := NULL;
    END;
END;
/

-- Now recreate the trigger with corrected syntax
DROP TRIGGER trg_colis_assign_price;

CREATE OR REPLACE TRIGGER trg_colis_assign_price
BEFORE INSERT OR UPDATE OF poids, type_colis, ville_destination, id_entrepot_localisation ON colis
FOR EACH ROW
DECLARE
  v_base NUMBER := 20;
  v_dest_entrepot NUMBER;
  v_livraison NUMBER;
BEGIN
  -- Price calculation
  IF :NEW.type_colis = 'FRAGILE' THEN
    v_base := 30;
  END IF;
  :NEW.prix := ROUND(:NEW.poids * v_base, 2);

  -- Auto-assign to a livraison if possible
  -- Only try to assign if id_livraison is NULL (not already assigned)
  IF :NEW.id_entrepot_localisation IS NOT NULL 
     AND :NEW.ville_destination IS NOT NULL 
     AND :NEW.id_livraison IS NULL THEN

    -- Find destination entrepot by city (first match)
    BEGIN
      SELECT id_entrepot
      INTO v_dest_entrepot
      FROM entrepots
      WHERE UPPER(ville) = UPPER(:NEW.ville_destination)
      FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_dest_entrepot := NULL;
    END;

    IF v_dest_entrepot IS NOT NULL THEN
      -- Try to find existing livraison with status CREEE
      BEGIN
        SELECT id_livraison
        INTO v_livraison
        FROM livraisons
        WHERE id_entrepot_source = :NEW.id_entrepot_localisation
          AND id_entrepot_destination = v_dest_entrepot
          AND statut = 'CREEE'
        ORDER BY id_livraison  -- Get the first one (oldest)
        FETCH FIRST 1 ROWS ONLY;

        :NEW.id_livraison := v_livraison;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- No livraison exists, use procedure to create one
          p_create_livraison_if_needed(
            :NEW.id_entrepot_localisation,
            v_dest_entrepot,
            v_livraison
          );
          :NEW.id_livraison := v_livraison;
      END;
    END IF;

  END IF;

END;
/

COMMIT;

PROMPT ========================================
PROMPT Trigger fixed!
PROMPT ========================================
PROMPT 
PROMPT The trigger now uses a helper procedure p_create_livraison_if_needed
PROMPT to handle the autonomous transaction part, avoiding syntax errors.
PROMPT 
PROMPT Next step: Assign existing colis without livraison
PROMPT 
PROMPT ========================================
PROMPT Assigning existing colis to livraisons:
PROMPT ========================================

-- Assign existing colis that don't have a livraison
UPDATE colis c1
SET id_livraison = (
  SELECT l.id_livraison
  FROM livraisons l
  WHERE l.id_entrepot_source = c1.id_entrepot_localisation
    AND l.id_entrepot_destination = (
      SELECT e.id_entrepot
      FROM entrepots e
      WHERE UPPER(e.ville) = UPPER(c1.ville_destination)
      FETCH FIRST 1 ROWS ONLY
    )
    AND l.statut = 'CREEE'
  ORDER BY l.id_livraison
  FETCH FIRST 1 ROWS ONLY
)
WHERE c1.id_livraison IS NULL
  AND c1.id_entrepot_localisation IS NOT NULL
  AND c1.ville_destination IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM entrepots e
    WHERE UPPER(e.ville) = UPPER(c1.ville_destination)
  );

COMMIT;

PROMPT Existing colis assigned to livraisons.
PROMPT 
PROMPT Verification:
SELECT 
  id_colis,
  id_entrepot_localisation,
  ville_destination,
  id_livraison,
  statut
FROM colis
ORDER BY id_colis;


