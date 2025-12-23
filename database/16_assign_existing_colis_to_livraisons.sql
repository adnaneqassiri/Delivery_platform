--------------------------------------------------
-- FIX: Assign existing colis that don't have a livraison
-- This script will create livraisons and assign existing colis to them
--------------------------------------------------

DECLARE
  v_dest_entrepot NUMBER;
  v_livraison NUMBER;
  v_count NUMBER := 0;
BEGIN
  -- Loop through all colis that don't have a livraison assigned
  FOR colis_rec IN (
    SELECT c.id_colis, c.id_entrepot_localisation, c.ville_destination
    FROM colis c
    WHERE c.id_livraison IS NULL
      AND c.id_entrepot_localisation IS NOT NULL
      AND c.ville_destination IS NOT NULL
      AND c.statut != 'ANNULE'
  ) LOOP
    -- Find destination entrepot by city
    BEGIN
      SELECT id_entrepot
      INTO v_dest_entrepot
      FROM entrepots
      WHERE UPPER(ville) = UPPER(colis_rec.ville_destination)
      FETCH FIRST 1 ROWS ONLY;
      
      -- Try to find existing livraison
      BEGIN
        SELECT id_livraison
        INTO v_livraison
        FROM livraisons
        WHERE id_entrepot_source = colis_rec.id_entrepot_localisation
          AND id_entrepot_destination = v_dest_entrepot
          AND statut = 'CREEE'
        FETCH FIRST 1 ROWS ONLY;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- Create new livraison
          INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
          VALUES (colis_rec.id_entrepot_localisation, v_dest_entrepot, 'CREEE', SYSTIMESTAMP)
          RETURNING id_livraison INTO v_livraison;
      END;
      
      -- Assign colis to livraison
      UPDATE colis
      SET id_livraison = v_livraison
      WHERE id_colis = colis_rec.id_colis;
      
      v_count := v_count + 1;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- No entrepot found for this city, skip
        NULL;
    END;
  END LOOP;
  
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('Assigned ' || v_count || ' colis to livraisons');
END;
/

COMMIT;

PROMPT Existing colis have been assigned to livraisons!



