--------------------------------------------------
-- DIAGNOSE: Why livreurs count is 0
-- This script will help identify the issue
--------------------------------------------------

PROMPT ========================================
PROMPT Diagnostic: Livreurs Count Issue
PROMPT ========================================
PROMPT 

-- Check all users with their roles and actif status
PROMPT 1. All users in utilisateurs table:
SELECT 
  id_utilisateur,
  nom_utilisateur,
  role,
  LENGTH(role) as role_length,
  UPPER(TRIM(role)) as role_normalized,
  actif,
  id_entrepot
FROM utilisateurs
ORDER BY id_utilisateur;

PROMPT 
PROMPT 2. Users with role containing 'LIVREUR' (case-insensitive):
SELECT 
  id_utilisateur,
  nom_utilisateur,
  role,
  actif,
  CASE 
    WHEN UPPER(TRIM(role)) = 'LIVREUR' THEN 'YES'
    ELSE 'NO'
  END as is_livreur_normalized
FROM utilisateurs
WHERE UPPER(role) LIKE '%LIVREUR%'
ORDER BY id_utilisateur;

PROMPT 
PROMPT 3. Count using exact match (current view logic):
SELECT COUNT(*) as count_exact_match
FROM utilisateurs 
WHERE role = 'LIVREUR' AND actif = 1;

PROMPT 
PROMPT 4. Count using normalized match (fixed logic):
SELECT COUNT(*) as count_normalized
FROM utilisateurs 
WHERE UPPER(TRIM(role)) = 'LIVREUR' AND actif = 1;

PROMPT 
PROMPT 5. Current KPI view result:
SELECT * FROM v_kpi_dashboard;

PROMPT 
PROMPT 6. Check if actif column has NULL values:
SELECT 
  COUNT(*) as total_users,
  COUNT(actif) as users_with_actif,
  COUNT(CASE WHEN actif = 1 THEN 1 END) as active_users,
  COUNT(CASE WHEN actif = 0 THEN 1 END) as inactive_users,
  COUNT(CASE WHEN actif IS NULL THEN 1 END) as null_actif
FROM utilisateurs;

PROMPT 
PROMPT ========================================
PROMPT Diagnostic complete!
PROMPT ========================================

