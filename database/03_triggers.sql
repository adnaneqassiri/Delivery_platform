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
-- PACKAGE: Prevent infinite loops in synchronization triggers
--------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_sync_flag AS
  g_syncing_user NUMBER := 0;
  g_syncing_entrepot NUMBER := 0;
END pkg_sync_flag;
/

--------------------------------------------------
-- PROCEDURE: Validate gestionnaire unique per entrepot (autonomous transaction)
--------------------------------------------------
CREATE OR REPLACE PROCEDURE p_validate_gestionnaire_unique_entrepot(
  p_id_entrepot NUMBER,
  p_id_utilisateur NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_count NUMBER;
BEGIN
  -- Check if another active gestionnaire is already assigned to this entrepot
  SELECT COUNT(*)
  INTO v_count
  FROM utilisateurs
  WHERE id_entrepot = p_id_entrepot
    AND role = 'GESTIONNAIRE'
    AND actif = 1
    AND id_utilisateur <> p_id_utilisateur;
  
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20020, 'Cet entrepot a deja un gestionnaire actif assigne');
  END IF;
  
  COMMIT;
END;
/

--------------------------------------------------
-- TRIGGER: VALIDATION - Un gestionnaire actif ne peut être assigné qu'à un seul entrepot
--------------------------------------------------
CREATE OR REPLACE TRIGGER trg_gestionnaire_unique_entrepot_before
BEFORE INSERT OR UPDATE OF id_entrepot, role, actif ON utilisateurs
FOR EACH ROW
WHEN (NEW.role = 'GESTIONNAIRE' AND NEW.actif = 1 AND NEW.id_entrepot IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_validate_gestionnaire_unique_entrepot(:NEW.id_entrepot, :NEW.id_utilisateur);
END;
/

-- Procedure to synchronize entrepots.id_user (autonomous transaction)
-- Only sync if not already syncing to avoid deadlock
CREATE OR REPLACE PROCEDURE p_sync_entrepot_gestionnaire(
  p_id_entrepot NUMBER,
  p_id_utilisateur NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Prevent deadlock: only sync if not already syncing from the other direction
  IF pkg_sync_flag.g_syncing_entrepot = 0 THEN
    pkg_sync_flag.g_syncing_user := 1;
    BEGIN
      -- Synchronize: Update entrepots.id_user to point to this gestionnaire
      UPDATE entrepots
      SET id_user = p_id_utilisateur
      WHERE id_entrepot = p_id_entrepot
        AND (id_user IS NULL OR id_user <> p_id_utilisateur);
    EXCEPTION
      WHEN OTHERS THEN
        pkg_sync_flag.g_syncing_user := 0;
        RAISE;
    END;
    pkg_sync_flag.g_syncing_user := 0;
  END IF;
  COMMIT;
END;
/

-- Synchronize entrepots.id_user after update (avoid infinite loop and mutating table)
CREATE OR REPLACE TRIGGER trg_gestionnaire_unique_entrepot_after
AFTER INSERT OR UPDATE OF id_entrepot, role, actif ON utilisateurs
FOR EACH ROW
WHEN (NEW.role = 'GESTIONNAIRE' AND NEW.actif = 1 AND NEW.id_entrepot IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  -- Only sync if entrepot doesn't already have this gestionnaire
  p_sync_entrepot_gestionnaire(:NEW.id_entrepot, :NEW.id_utilisateur);
END;
/

--------------------------------------------------
-- PROCEDURE: Validate entrepot gestionnaire (autonomous transaction)
--------------------------------------------------
CREATE OR REPLACE PROCEDURE p_validate_entrepot_gestionnaire(
  p_id_user NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_role VARCHAR2(20);
  v_actif NUMBER;
BEGIN
  -- Verify that id_user is a gestionnaire
  SELECT role, actif
  INTO v_role, v_actif
  FROM utilisateurs
  WHERE id_utilisateur = p_id_user;
  
  IF v_role <> 'GESTIONNAIRE' THEN
    RAISE_APPLICATION_ERROR(-20021, 'Seul un gestionnaire peut etre assigne a un entrepot');
  END IF;
  
  IF v_actif <> 1 THEN
    RAISE_APPLICATION_ERROR(-20022, 'Seul un gestionnaire actif peut etre assigne a un entrepot');
  END IF;
  
  COMMIT;
END;
/

--------------------------------------------------
-- TRIGGER: VALIDATION - Un entrepot ne peut avoir qu'un seul gestionnaire actif
-- (via entrepots.id_user) et synchronisation bidirectionnelle
--------------------------------------------------
CREATE OR REPLACE TRIGGER trg_entrepot_unique_gestionnaire_before
BEFORE INSERT OR UPDATE OF id_user ON entrepots
FOR EACH ROW
WHEN (NEW.id_user IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_validate_entrepot_gestionnaire(:NEW.id_user);
END;
/

-- Procedure to synchronize utilisateurs.id_entrepot (autonomous transaction)
-- Only sync if not already syncing to avoid deadlock
CREATE OR REPLACE PROCEDURE p_sync_gestionnaire_entrepot(
  p_id_user NUMBER,
  p_id_entrepot NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Prevent deadlock: only sync if not already syncing from the other direction
  IF pkg_sync_flag.g_syncing_user = 0 THEN
    pkg_sync_flag.g_syncing_entrepot := 1;
    BEGIN
      -- Synchronize: Update utilisateurs.id_entrepot to point to this entrepot
      UPDATE utilisateurs
      SET id_entrepot = p_id_entrepot
      WHERE id_utilisateur = p_id_user
        AND role = 'GESTIONNAIRE'
        AND actif = 1
        AND (id_entrepot IS NULL OR id_entrepot <> p_id_entrepot);
    EXCEPTION
      WHEN OTHERS THEN
        pkg_sync_flag.g_syncing_entrepot := 0;
        RAISE;
    END;
    pkg_sync_flag.g_syncing_entrepot := 0;
  END IF;
  COMMIT;
END;
/

-- Synchronize utilisateurs.id_entrepot after update (avoid infinite loop and mutating table)
-- NOTE: This trigger is kept for backward compatibility, but ideally synchronization
-- should only happen in one direction (gestionnaire -> entrepot) to avoid deadlocks
CREATE OR REPLACE TRIGGER trg_entrepot_unique_gestionnaire_after
AFTER INSERT OR UPDATE OF id_user ON entrepots
FOR EACH ROW
WHEN (NEW.id_user IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  -- Only sync if gestionnaire doesn't already have this entrepot
  p_sync_gestionnaire_entrepot(:NEW.id_user, :NEW.id_entrepot);
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

