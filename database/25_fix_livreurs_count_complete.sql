--------------------------------------------------
-- FIX: Livreurs count in KPI dashboard - Complete Fix
-- 1. Update the view to use UPPER(TRIM(role))
-- 2. Normalize existing roles in the database
-- 3. Update the package procedure to normalize roles on creation
--------------------------------------------------

-- Step 1: Normalize existing roles in utilisateurs table
UPDATE utilisateurs
SET role = UPPER(TRIM(role))
WHERE role != UPPER(TRIM(role));

-- Step 2: Ensure all users have actif = 1 if not set
UPDATE utilisateurs
SET actif = 1
WHERE actif IS NULL;

-- Step 3: Update the KPI view to use normalized role comparison
CREATE OR REPLACE VIEW v_kpi_dashboard AS
SELECT
  (SELECT COUNT(*) FROM colis) AS colis_count,
  (SELECT COUNT(*) FROM livraisons) AS livraisons_count,
  (SELECT NVL(SUM(prix),0) FROM colis WHERE statut IN ('LIVRE','RECUPEREE')) AS chiffre_affaire,
  (SELECT COUNT(*) FROM utilisateurs WHERE UPPER(TRIM(role)) = 'LIVREUR' AND actif = 1) AS livreurs_count,
  (SELECT COUNT(*) FROM entrepots) AS entrepots_count,
  (SELECT COUNT(*) FROM clients) AS clients_count
FROM dual;

COMMIT;

PROMPT ========================================
PROMPT Fix completed!
PROMPT ========================================
PROMPT 
PROMPT 1. Existing roles have been normalized (uppercase, trimmed)
PROMPT 2. All users without actif value have been set to 1
PROMPT 3. KPI view updated to use normalized role comparison
PROMPT 
PROMPT Next step: Run 12_fix_package_syntax.sql to update the package
PROMPT procedure p_creer_utilisateur to normalize roles on creation.

