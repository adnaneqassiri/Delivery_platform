--------------------------------------------------
-- FIX: Trigger mutating table error when cancelling colis
-- Change from AFTER UPDATE to BEFORE UPDATE and set id_livraison directly
-- This avoids the mutating table error
--------------------------------------------------

-- Drop the old trigger
DROP TRIGGER trg_colis_annulation_unassign;

-- Create the fixed trigger
CREATE OR REPLACE TRIGGER trg_colis_annulation_unassign
BEFORE UPDATE OF statut ON colis
FOR EACH ROW
WHEN (NEW.statut = 'ANNULE' AND OLD.statut <> 'ANNULE')
BEGIN
  -- Unassign from livraison by setting id_livraison to NULL directly
  -- This avoids mutating table error since we're modifying :NEW instead of doing an UPDATE
  :NEW.id_livraison := NULL;
  
  -- History will be inserted by p_modifier_statut_colis procedure, not here
END;
/

COMMIT;

PROMPT Trigger trg_colis_annulation_unassign fixed!
PROMPT 
PROMPT The trigger now uses BEFORE UPDATE to set id_livraison = NULL directly,
PROMPT avoiding the mutating table error.


