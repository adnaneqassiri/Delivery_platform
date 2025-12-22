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
  TYPE t_route_rec IS RECORD (
    id_entrepot_source NUMBER,
    id_entrepot_destination NUMBER
  );
  TYPE t_route_tab IS TABLE OF t_route_rec;
  g_colis_data t_colis_tab;
  g_routes t_route_tab;
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
  
  -- Set date_livraison
  :NEW.date_livraison := SYSDATE;
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

  -- Note: Creating new livraison moved to statement-level trigger to avoid mutating table

END;
/

-- Update AFTER trigger to store route info instead of inserting
CREATE OR REPLACE TRIGGER trg_livraison_arrivee_after
AFTER UPDATE OF statut ON livraisons
FOR EACH ROW
WHEN (NEW.statut = 'LIVREE' AND OLD.statut = 'EN_COURS')
DECLARE
  v_user NUMBER;
  v_route pkg_livraison_temp.t_route_rec;
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

  -- Store route info for statement-level trigger
  IF pkg_livraison_temp.g_routes IS NULL THEN
    pkg_livraison_temp.g_routes := pkg_livraison_temp.t_route_tab();
  END IF;
  v_route.id_entrepot_source := :NEW.id_entrepot_source;
  v_route.id_entrepot_destination := :NEW.id_entrepot_destination;
  pkg_livraison_temp.g_routes.EXTEND;
  pkg_livraison_temp.g_routes(pkg_livraison_temp.g_routes.COUNT) := v_route;

  -- Reset colis data
  pkg_livraison_temp.g_colis_data := pkg_livraison_temp.t_colis_tab();
  pkg_livraison_temp.g_initialized := FALSE;

END;
/

-- Create statement-level trigger to create new livraison (runs after all row updates)
CREATE OR REPLACE TRIGGER trg_livraison_arrivee_statement
AFTER UPDATE OF statut ON livraisons
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Create new livraison for stored routes
  IF pkg_livraison_temp.g_routes IS NOT NULL AND pkg_livraison_temp.g_routes.COUNT > 0 THEN
    FOR i IN 1..pkg_livraison_temp.g_routes.COUNT LOOP
      DECLARE
        v_exists NUMBER;
      BEGIN
        -- Check if a CREEE livraison already exists for this route
        SELECT COUNT(*) INTO v_exists
        FROM livraisons
        WHERE id_entrepot_source = pkg_livraison_temp.g_routes(i).id_entrepot_source
          AND id_entrepot_destination = pkg_livraison_temp.g_routes(i).id_entrepot_destination
          AND statut = 'CREEE';
        
        IF v_exists = 0 THEN
          INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
          VALUES (pkg_livraison_temp.g_routes(i).id_entrepot_source, 
                  pkg_livraison_temp.g_routes(i).id_entrepot_destination, 
                  'CREEE', 
                  SYSTIMESTAMP);
        END IF;
      END;
    END LOOP;
    
    -- Clear routes
    pkg_livraison_temp.g_routes := pkg_livraison_temp.t_route_tab();
  END IF;
  
  COMMIT;
END;
/

COMMIT;

PROMPT Trigger fixed successfully using package variable approach!

