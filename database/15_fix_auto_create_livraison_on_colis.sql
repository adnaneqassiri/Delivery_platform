--------------------------------------------------
-- FIX: Auto-create livraison when colis is created if it doesn't exist
-- This ensures that colis can always be assigned to a livraison
--------------------------------------------------

CREATE OR REPLACE TRIGGER trg_colis_assign_price
BEFORE INSERT OR UPDATE OF poids, type_colis, ville_destination, id_entrepot_localisation ON colis
FOR EACH ROW
DECLARE
  v_base NUMBER := 20;
  v_dest_entrepot NUMBER;
  v_livraison NUMBER;
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Price
  IF :NEW.type_colis = 'FRAGILE' THEN
    v_base := 30;
  END IF;
  :NEW.prix := ROUND(:NEW.poids * v_base, 2);

  -- Auto-assign to a livraison if possible
  IF :NEW.id_entrepot_localisation IS NOT NULL AND :NEW.ville_destination IS NOT NULL THEN

    -- find destination entrepot by city (first match)
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
      -- Try to find existing livraison
      BEGIN
        SELECT id_livraison
        INTO v_livraison
        FROM livraisons
        WHERE id_entrepot_source = :NEW.id_entrepot_localisation
          AND id_entrepot_destination = v_dest_entrepot
          AND statut = 'CREEE'
        FETCH FIRST 1 ROWS ONLY;

        :NEW.id_livraison := v_livraison;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- No livraison exists, create one automatically
          BEGIN
            INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
            VALUES (:NEW.id_entrepot_localisation, v_dest_entrepot, 'CREEE', SYSTIMESTAMP)
            RETURNING id_livraison INTO v_livraison;
            
            :NEW.id_livraison := v_livraison;
            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              -- If creation fails (e.g., duplicate), try to get existing one
              BEGIN
                SELECT id_livraison
                INTO v_livraison
                FROM livraisons
                WHERE id_entrepot_source = :NEW.id_entrepot_localisation
                  AND id_entrepot_destination = v_dest_entrepot
                  AND statut = 'CREEE'
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

PROMPT Trigger trg_colis_assign_price updated to auto-create livraisons!
PROMPT 
PROMPT Now when you create a colis, if no livraison exists for that route,
PROMPT one will be created automatically and the colis will be assigned to it.

