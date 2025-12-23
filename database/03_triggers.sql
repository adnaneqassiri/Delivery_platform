--------------------------------------------------
-- TRIGGERS (CONSOLIDATED - All fixes integrated)
-- Run this script to create all triggers
--------------------------------------------------

--------------------------------------------------
-- AUTO ID TRIGGERS
--------------------------------------------------
CREATE OR REPLACE TRIGGER trg_utilisateurs_id
BEFORE INSERT ON utilisateurs
FOR EACH ROW
BEGIN
  IF :NEW.id_utilisateur IS NULL THEN
    :NEW.id_utilisateur := seq_utilisateurs.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_entrepots_id
BEFORE INSERT ON entrepots
FOR EACH ROW
BEGIN
  IF :NEW.id_entrepot IS NULL THEN
    :NEW.id_entrepot := seq_entrepots.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_vehicules_id
BEFORE INSERT ON vehicules
FOR EACH ROW
BEGIN
  IF :NEW.id_vehicule IS NULL THEN
    :NEW.id_vehicule := seq_vehicules.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_clients_id
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
  IF :NEW.id_client IS NULL THEN
    :NEW.id_client := seq_clients.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_livraisons_id
BEFORE INSERT ON livraisons
FOR EACH ROW
BEGIN
  IF :NEW.id_livraison IS NULL THEN
    :NEW.id_livraison := seq_livraisons.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_colis_id
BEFORE INSERT ON colis
FOR EACH ROW
BEGIN
  IF :NEW.id_colis IS NULL THEN
    :NEW.id_colis := seq_colis.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_hist_colis_id
BEFORE INSERT ON historique_statut_colis
FOR EACH ROW
BEGIN
  IF :NEW.id_history IS NULL THEN
    :NEW.id_history := seq_hist_colis.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_hist_liv_id
BEFORE INSERT ON historique_statut_livraisons
FOR EACH ROW
BEGIN
  IF :NEW.id_history IS NULL THEN
    :NEW.id_history := seq_hist_liv.NEXTVAL;
  END IF;
END;
/

--------------------------------------------------
-- TRIGGER: CALCUL PRIX + ASSIGN LIVRAISON BY ville_destination
--------------------------------------------------
--------------------------------------------------
-- HELPER PROCEDURES FOR TRIGGERS
--------------------------------------------------

-- Helper procedure for creating livraisons (autonomous transaction)
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

-- Helper procedure for creating new livraison after delivery (autonomous transaction)
CREATE OR REPLACE PROCEDURE p_create_new_livraison_after_delivery(
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
EXCEPTION
  WHEN OTHERS THEN
    -- If creation fails, ignore (don't break the trigger)
    NULL;
END;
/

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

--------------------------------------------------
-- TRIGGER: if colis becomes ANNULE -> unassign from livraison
--------------------------------------------------
CREATE OR REPLACE TRIGGER trg_colis_annulation_unassign
BEFORE UPDATE OF statut ON colis
FOR EACH ROW
WHEN (NEW.statut = 'ANNULE' AND OLD.statut <> 'ANNULE')
BEGIN
  -- Unassign from livraison by setting id_livraison to NULL
  :NEW.id_livraison := NULL;
  
  -- History will be inserted by p_modifier_statut_colis procedure
END;
/

--------------------------------------------------
-- TRIGGER: LIVRAISON DEPART (CREEE -> EN_COURS)
--    Update: vehicule => EN_UTILISATION, colis => EN_COURS
--    Insert histories
--    Auto-create new CREEE livraison for same route
--------------------------------------------------
CREATE OR REPLACE TRIGGER trg_livraison_depart
BEFORE UPDATE OF statut ON livraisons
FOR EACH ROW
WHEN (NEW.statut = 'EN_COURS' AND OLD.statut = 'CREEE')
DECLARE
  v_user NUMBER;
BEGIN
  v_user := :NEW.id_livreur;

  -- Vehicle status
  IF :NEW.id_vehicule IS NOT NULL THEN
    UPDATE vehicules
    SET statut = 'EN_UTILISATION'
    WHERE id_vehicule = :NEW.id_vehicule;
  END IF;

  -- Colis statuses (fix: use ENREGISTRE not ENREGISTREE)
  UPDATE colis
  SET statut = 'EN_COURS'
  WHERE id_livraison = :NEW.id_livraison
    AND statut = 'ENREGISTRE';

  -- Livraison history
  INSERT INTO historique_statut_livraisons(id_livraison, statut_avant, statut_apres, id_utilisateur)
  VALUES (:NEW.id_livraison, :OLD.statut, :NEW.statut, v_user);

  -- Colis history (one per colis)
  FOR r IN (SELECT id_colis, statut FROM colis WHERE id_livraison = :NEW.id_livraison) LOOP
    INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
    VALUES (r.id_colis, r.statut, 'EN_COURS', v_user);
  END LOOP;
END;
/

-- Trigger to auto-create new CREEE livraison when one is taken
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

--------------------------------------------------
-- TRIGGER: LIVRAISON ARRIVEE (EN_COURS -> LIVREE)
--    Update: vehicule => DISPONIBLE, colis => LIVRE
--    Insert histories
--    Auto-create NEW livraison for same route (fixed with autonomous transaction)
--------------------------------------------------
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

  -- Colis statuses (delivered - mark as LIVRE at destination)
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
  -- Use autonomous transaction procedure to avoid mutating table error
  BEGIN
    p_create_new_livraison_after_delivery(:NEW.id_entrepot_source, :NEW.id_entrepot_destination);
  EXCEPTION
    WHEN OTHERS THEN
      -- If creation fails, continue without creating new livraison
      NULL;
  END;

END;
/

COMMIT;

PROMPT Triggers created successfully!

