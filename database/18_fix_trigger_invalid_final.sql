--------------------------------------------------
-- FIX: Trigger invalid error - Use procedure for autonomous transaction
-- This is a cleaner approach than nested PRAGMA AUTONOMOUS_TRANSACTION
--------------------------------------------------

-- Create a procedure to handle the creation of new livraison
CREATE OR REPLACE PROCEDURE p_create_new_livraison_if_needed(
  p_id_entrepot_source NUMBER,
  p_id_entrepot_destination NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_exists NUMBER;
BEGIN
  -- Check if a CREEE livraison already exists for this route
  SELECT COUNT(*)
  INTO v_exists
  FROM livraisons
  WHERE id_entrepot_source = p_id_entrepot_source
    AND id_entrepot_destination = p_id_entrepot_destination
    AND statut = 'CREEE';
  
  -- If no CREEE livraison exists, create one
  IF v_exists = 0 THEN
    INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
    VALUES (p_id_entrepot_source, p_id_entrepot_destination, 'CREEE', SYSTIMESTAMP);
  END IF;
  
  COMMIT;
END;
/

-- Drop the old trigger
DROP TRIGGER trg_livraison_arrivee;

-- Create the fixed trigger
CREATE OR REPLACE TRIGGER trg_livraison_arrivee
BEFORE UPDATE OF statut ON livraisons
FOR EACH ROW
WHEN (NEW.statut = 'LIVREE' AND OLD.statut = 'EN_COURS')
DECLARE
  v_user NUMBER;
BEGIN
  v_user := :NEW.id_livreur;

  -- Vehicle status
  IF :NEW.id_vehicule IS NOT NULL THEN
    UPDATE vehicules
    SET statut = 'DISPONIBLE'
    WHERE id_vehicule = :NEW.id_vehicule;
  END IF;

  -- Colis statuses (delivered)
  UPDATE colis
  SET statut = 'LIVRE',
      id_entrepot_localisation = :NEW.id_entrepot_destination
  WHERE id_livraison = :NEW.id_livraison
    AND statut = 'EN_COURS';

  -- Livraison history
  INSERT INTO historique_statut_livraisons(id_livraison, statut_avant, statut_apres, id_utilisateur)
  VALUES (:NEW.id_livraison, :OLD.statut, :NEW.statut, v_user);

  -- Colis history
  FOR r IN (SELECT id_colis, statut FROM colis WHERE id_livraison = :NEW.id_livraison) LOOP
    INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
    VALUES (r.id_colis, r.statut, 'LIVRE', v_user);
  END LOOP;

  -- ensure date_livraison
  :NEW.date_livraison := SYSDATE;

  -- Create a new livraison row for same route (keeps availability)
  -- Use procedure with autonomous transaction to avoid mutating table error
  BEGIN
    p_create_new_livraison_if_needed(:NEW.id_entrepot_source, :NEW.id_entrepot_destination);
  EXCEPTION
    WHEN OTHERS THEN
      -- If procedure fails, continue without creating new livraison
      NULL;
  END;

END;
/

COMMIT;

PROMPT Trigger trg_livraison_arrivee fixed using procedure approach!
PROMPT The trigger now uses a procedure with PRAGMA AUTONOMOUS_TRANSACTION.

