--------------------------------------------------
-- FIX: Livreurs count in KPI dashboard - FINAL FIX
-- This script will:
-- 1. Normalize all existing roles (uppercase, trimmed)
-- 2. Ensure all users have actif = 1
-- 3. Update the KPI view to use normalized role comparison
-- 4. Verify the fix
--------------------------------------------------

PROMPT ========================================
PROMPT Step 1: Normalizing existing roles...
PROMPT ========================================

-- Normalize all roles to uppercase and trim whitespace
UPDATE utilisateurs
SET role = UPPER(TRIM(role))
WHERE role != UPPER(TRIM(role));

PROMPT Roles normalized.

PROMPT 
PROMPT ========================================
PROMPT Step 2: Ensuring all users are active...
PROMPT ========================================

-- Set actif = 1 for all users where it's NULL or 0 (assuming we want them all active)
UPDATE utilisateurs
SET actif = 1
WHERE actif IS NULL OR actif = 0;

PROMPT All users set to active.

PROMPT 
PROMPT ========================================
PROMPT Step 3: Updating KPI view...
PROMPT ========================================

-- Update the KPI view to use normalized role comparison
CREATE OR REPLACE VIEW v_kpi_dashboard AS
SELECT
  (SELECT COUNT(*) FROM colis) AS colis_count,
  (SELECT COUNT(*) FROM livraisons) AS livraisons_count,
  (SELECT NVL(SUM(prix),0) FROM colis WHERE statut IN ('LIVRE','RECUPEREE')) AS chiffre_affaire,
  (SELECT COUNT(*) FROM utilisateurs WHERE UPPER(TRIM(role)) = 'LIVREUR' AND actif = 1) AS livreurs_count,
  (SELECT COUNT(*) FROM entrepots) AS entrepots_count,
  (SELECT COUNT(*) FROM clients) AS clients_count
FROM dual;

PROMPT KPI view updated.

PROMPT 
PROMPT ========================================
PROMPT Step 4: Verification...
PROMPT ========================================

-- Show current state
PROMPT 
PROMPT Current livreurs in database:
SELECT 
  id_utilisateur,
  nom_utilisateur,
  role,
  actif,
  CASE 
    WHEN UPPER(TRIM(role)) = 'LIVREUR' AND actif = 1 THEN 'YES - Will be counted'
    WHEN UPPER(TRIM(role)) = 'LIVREUR' AND actif != 1 THEN 'NO - Not active'
    ELSE 'NO - Not a livreur'
  END as will_be_counted
FROM utilisateurs
WHERE UPPER(TRIM(role)) = 'LIVREUR'
ORDER BY id_utilisateur;

PROMPT 
PROMPT Count from view:
SELECT livreurs_count FROM v_kpi_dashboard;

PROMPT 
PROMPT Direct count query:
SELECT COUNT(*) as direct_count
FROM utilisateurs 
WHERE UPPER(TRIM(role)) = 'LIVREUR' AND actif = 1;

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Fix completed successfully!
PROMPT ========================================
PROMPT 
PROMPT The livreurs_count should now be correct in the dashboard.
PROMPT Please refresh the dashboard page to see the updated count.


