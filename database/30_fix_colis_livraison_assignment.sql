--------------------------------------------------
-- FIX: Colis assignment to livraisons
-- The issue is that the trigger might not find existing livraisons
-- properly. Let's improve the logic to ensure colis are assigned
-- to the same livraison when they have the same route.
--------------------------------------------------

-- First, let's see what livraisons exist and their status
PROMPT ========================================
PROMPT Current state of livraisons:
PROMPT ========================================
SELECT 
  id_livraison,
  id_entrepot_source,
  id_entrepot_destination,
  statut,
  (SELECT COUNT(*) FROM colis WHERE id_livraison = l.id_livraison) AS nb_colis
FROM livraisons l
ORDER BY id_livraison;

PROMPT 
PROMPT ========================================
PROMPT Current colis and their livraisons:
PROMPT ========================================
SELECT 
  id_colis,
  id_entrepot_localisation,
  ville_destination,
  id_livraison,
  statut
FROM colis
ORDER BY id_colis;

PROMPT 
PROMPT ========================================
PROMPT Fixing trigger to better handle assignment:
PROMPT ========================================

-- Drop and recreate the trigger with better logic
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
          -- No livraison exists, create one using autonomous transaction
          DECLARE
            PRAGMA AUTONOMOUS_TRANSACTION;
            v_new_livraison NUMBER;
          BEGIN
            INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
            VALUES (:NEW.id_entrepot_localisation, v_dest_entrepot, 'CREEE', SYSTIMESTAMP)
            RETURNING id_livraison INTO v_new_livraison;
            
            COMMIT;
            :NEW.id_livraison := v_new_livraison;
          EXCEPTION
            WHEN OTHERS THEN
              -- If creation fails (e.g., duplicate due to concurrent insert), try to get existing one
              BEGIN
                SELECT id_livraison
                INTO v_livraison
                FROM livraisons
                WHERE id_entrepot_source = :NEW.id_entrepot_localisation
                  AND id_entrepot_destination = v_dest_entrepot
                  AND statut = 'CREEE'
                ORDER BY id_livraison
                FETCH FIRST 1 ROWS ONLY;
                
                :NEW.id_livraison := v_livraison;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- Keep id_livraison NULL if still not found
                  NULL;
              END;
          END;
      END;
    END IF;

  END IF;

END;
/

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Trigger fixed!
PROMPT ========================================
PROMPT 
PROMPT The trigger now:
PROMPT 1. Only assigns if id_livraison is NULL (not already assigned)
PROMPT 2. Looks for existing CREEE livraisons first
PROMPT 3. Uses autonomous transaction only for creating new livraisons
PROMPT 4. Orders by id_livraison to get the oldest one first
PROMPT 
PROMPT 
PROMPT ========================================
PROMPT Assigning existing colis without livraison:
PROMPT ========================================

-- Assign existing colis that don't have a livraison to the appropriate livraison
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
PROMPT Verification - colis and their livraisons:
SELECT 
  id_colis,
  id_entrepot_localisation,
  ville_destination,
  id_livraison,
  statut
FROM colis
ORDER BY id_colis;

