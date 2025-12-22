--------------------------------------------------
-- FIX: Auto-create new livraison when one is taken or delivered
-- The statement-level trigger might not be working correctly
-- Let's add logic to create new livraison when taken (CREEE -> EN_COURS)
-- and ensure it works when delivered (EN_COURS -> LIVREE)
--------------------------------------------------

-- Update package to also store routes when livraison is taken
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

-- Create trigger for when livraison is taken (CREEE -> EN_COURS)
-- This should create a new CREEE livraison for the same route
CREATE OR REPLACE TRIGGER trg_livraison_depart_create
AFTER UPDATE OF statut ON livraisons
FOR EACH ROW
WHEN (NEW.statut = 'EN_COURS' AND OLD.statut = 'CREEE')
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_exists NUMBER;
BEGIN
  -- Check if a CREEE livraison already exists for this route
  SELECT COUNT(*) INTO v_exists
  FROM livraisons
  WHERE id_entrepot_source = :OLD.id_entrepot_source
    AND id_entrepot_destination = :OLD.id_entrepot_destination
    AND statut = 'CREEE';
  
  -- If no CREEE livraison exists for this route, create one
  IF v_exists = 0 THEN
    INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
    VALUES (:OLD.id_entrepot_source, :OLD.id_entrepot_destination, 'CREEE', SYSTIMESTAMP);
  END IF;
  
  COMMIT;
END;
/

-- Fix the statement-level trigger to ensure it works correctly
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
        
        -- If no CREEE livraison exists, create one
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

PROMPT Auto-create livraison triggers fixed!

