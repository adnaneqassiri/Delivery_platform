--------------------------------------------------
-- FIX: Mutating Table Error in trg_livraison_arrivee
-- Use package variable approach to avoid mutating table error
--------------------------------------------------

-- First, create a package to hold temporary data
CREATE OR REPLACE PACKAGE pkg_livraison_temp AS
  TYPE t_colis_rec IS RECORD (
    id_colis NUMBER,
    statut VARCHAR2(20)
  );
  TYPE t_colis_tab IS TABLE OF t_colis_rec;
  g_colis_data t_colis_tab;
  g_initialized BOOLEAN := FALSE;
END pkg_livraison_temp;
/

-- Drop the old trigger
DROP TRIGGER trg_livraison_arrivee;

-- Create BEFORE trigger to collect colis data
CREATE OR REPLACE TRIGGER trg_livraison_arrivee_before
BEFORE UPDATE OF statut ON livraisons
FOR EACH ROW
WHEN (NEW.statut = 'LIVREE' AND OLD.statut = 'EN_COURS')
DECLARE
BEGIN
  -- Collect colis IDs and statuses before update
  SELECT id_colis, statut
  BULK COLLECT INTO pkg_livraison_temp.g_colis_data
  FROM colis
  WHERE id_livraison = :OLD.id_livraison;
  
  pkg_livraison_temp.g_initialized := TRUE;
END;
/

-- Create AFTER trigger to perform updates
CREATE OR REPLACE TRIGGER trg_livraison_arrivee_after
AFTER UPDATE OF statut ON livraisons
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

  -- Colis statuses (delivered) - use collected data
  IF pkg_livraison_temp.g_initialized AND pkg_livraison_temp.g_colis_data.COUNT > 0 THEN
    FOR i IN 1..pkg_livraison_temp.g_colis_data.COUNT LOOP
      UPDATE colis
      SET statut = 'LIVRE',
          id_entrepot_localisation = :NEW.id_entrepot_destination
      WHERE id_colis = pkg_livraison_temp.g_colis_data(i).id_colis
        AND statut = 'EN_COURS';
    END LOOP;
  END IF;

  -- Livraison history
  INSERT INTO historique_statut_livraisons(id_livraison, statut_avant, statut_apres, id_utilisateur)
  VALUES (:NEW.id_livraison, :OLD.statut, :NEW.statut, v_user);

  -- Colis history - use collected data
  IF pkg_livraison_temp.g_initialized AND pkg_livraison_temp.g_colis_data.COUNT > 0 THEN
    FOR i IN 1..pkg_livraison_temp.g_colis_data.COUNT LOOP
      INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
      VALUES (pkg_livraison_temp.g_colis_data(i).id_colis, 
              pkg_livraison_temp.g_colis_data(i).statut, 
              'LIVRE', 
              v_user);
    END LOOP;
  END IF;

  -- Reset package variable
  pkg_livraison_temp.g_colis_data := pkg_livraison_temp.t_colis_tab();
  pkg_livraison_temp.g_initialized := FALSE;

  -- Create a new livraison row for same route (keeps availability)
  INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
  VALUES (:NEW.id_entrepot_source, :NEW.id_entrepot_destination, 'CREEE', SYSTIMESTAMP);

END;
/

COMMIT;

PROMPT Trigger fixed successfully using package variable approach!


