--------------------------------------------------
-- FIX DEADLOCK ERROR
-- Run this script to fix the deadlock error
--------------------------------------------------

PROMPT Fixing deadlock error in synchronization triggers...

-- Drop existing triggers
DROP TRIGGER trg_gestionnaire_unique_entrepot_after;
DROP TRIGGER trg_entrepot_unique_gestionnaire_after;

-- Recreate procedure to sync entrepot (check both flags to prevent deadlock)
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

-- Recreate procedure to sync gestionnaire (check both flags to prevent deadlock)
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

-- Recreate triggers
CREATE OR REPLACE TRIGGER trg_gestionnaire_unique_entrepot_after
AFTER INSERT OR UPDATE OF id_entrepot, role, actif ON utilisateurs
FOR EACH ROW
WHEN (NEW.role = 'GESTIONNAIRE' AND NEW.actif = 1 AND NEW.id_entrepot IS NOT NULL)
BEGIN
  -- Use autonomous transaction procedure to avoid mutating table error
  p_sync_entrepot_gestionnaire(:NEW.id_entrepot, :NEW.id_utilisateur);
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

PROMPT Deadlock fix applied successfully!
PROMPT The synchronization now checks both flags to prevent circular updates.

