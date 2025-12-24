--------------------------------------------------
-- FIX MUTATING TABLE ERROR
-- Run this script to fix the mutating table error
--------------------------------------------------

PROMPT Fixing mutating table errors in all gestionnaire/entrepot triggers...

-- Drop existing triggers
DROP TRIGGER trg_gestionnaire_unique_entrepot_before;
DROP TRIGGER trg_gestionnaire_unique_entrepot_after;
DROP TRIGGER trg_entrepot_unique_gestionnaire_before;
DROP TRIGGER trg_entrepot_unique_gestionnaire_after;

-- Create autonomous procedure for validation (gestionnaire -> entrepot)
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

-- Create autonomous procedure for synchronization (gestionnaire -> entrepot)
CREATE OR REPLACE PROCEDURE p_sync_entrepot_gestionnaire(
  p_id_entrepot NUMBER,
  p_id_utilisateur NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Prevent infinite loop
  IF pkg_sync_flag.g_syncing_user = 0 THEN
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

-- Create autonomous procedure for validation (entrepot -> gestionnaire)
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

-- Create autonomous procedure for synchronization (entrepot -> gestionnaire)
CREATE OR REPLACE PROCEDURE p_sync_gestionnaire_entrepot(
  p_id_user NUMBER,
  p_id_entrepot NUMBER
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- Prevent infinite loop
  IF pkg_sync_flag.g_syncing_entrepot = 0 THEN
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

-- Recreate triggers using autonomous procedures
CREATE OR REPLACE TRIGGER trg_gestionnaire_unique_entrepot_before
BEFORE INSERT OR UPDATE OF id_entrepot, role, actif ON utilisateurs
FOR EACH ROW
WHEN (NEW.role = 'GESTIONNAIRE' AND NEW.actif = 1 AND NEW.id_entrepot IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_validate_gestionnaire_unique_entrepot(:NEW.id_entrepot, :NEW.id_utilisateur);
END;
/

CREATE OR REPLACE TRIGGER trg_gestionnaire_unique_entrepot_after
AFTER INSERT OR UPDATE OF id_entrepot, role, actif ON utilisateurs
FOR EACH ROW
WHEN (NEW.role = 'GESTIONNAIRE' AND NEW.actif = 1 AND NEW.id_entrepot IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_sync_entrepot_gestionnaire(:NEW.id_entrepot, :NEW.id_utilisateur);
END;
/

CREATE OR REPLACE TRIGGER trg_entrepot_unique_gestionnaire_before
BEFORE INSERT OR UPDATE OF id_user ON entrepots
FOR EACH ROW
WHEN (NEW.id_user IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_validate_entrepot_gestionnaire(:NEW.id_user);
END;
/

CREATE OR REPLACE TRIGGER trg_entrepot_unique_gestionnaire_after
AFTER INSERT OR UPDATE OF id_user ON entrepots
FOR EACH ROW
WHEN (NEW.id_user IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_sync_gestionnaire_entrepot(:NEW.id_user, :NEW.id_entrepot);
END;
/

COMMIT;

PROMPT All triggers fixed successfully!

