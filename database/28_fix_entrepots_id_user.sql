--------------------------------------------------
-- FIX: Update entrepots.id_user for existing gestionnaires
-- This script sets id_user for entrepots that don't have one
-- but have gestionnaires assigned to them
--------------------------------------------------

PROMPT ========================================
PROMPT Step 1: Updating entrepots.id_user for existing gestionnaires
PROMPT ========================================

-- Update entrepots.id_user with the first gestionnaire assigned to each entrepot
-- that doesn't have an id_user yet
UPDATE entrepots e
SET id_user = (
  SELECT u.id_utilisateur
  FROM utilisateurs u
  WHERE u.id_entrepot = e.id_entrepot
    AND UPPER(TRIM(u.role)) = 'GESTIONNAIRE'
    AND u.actif = 1
  FETCH FIRST 1 ROWS ONLY
)
WHERE e.id_user IS NULL
  AND EXISTS (
    SELECT 1
    FROM utilisateurs u
    WHERE u.id_entrepot = e.id_entrepot
      AND UPPER(TRIM(u.role)) = 'GESTIONNAIRE'
      AND u.actif = 1
  );

PROMPT Updated entrepots with gestionnaires.

PROMPT 
PROMPT ========================================
PROMPT Step 2: Verification
PROMPT ========================================

PROMPT 
PROMPT Entreports and their assigned gestionnaires:
SELECT 
  e.id_entrepot,
  e.ville || ' - ' || e.adresse AS entrepot_name,
  e.id_user AS entrepot_manager_id,
  u.nom_utilisateur AS manager_username,
  u.role AS manager_role,
  (SELECT COUNT(*) 
   FROM utilisateurs u2 
   WHERE u2.id_entrepot = e.id_entrepot 
     AND UPPER(TRIM(u2.role)) = 'GESTIONNAIRE' 
     AND u2.actif = 1) AS total_gestionnaires
FROM entrepots e
LEFT JOIN utilisateurs u ON e.id_user = u.id_utilisateur
ORDER BY e.id_entrepot;

PROMPT 
PROMPT Entreports still without a manager (id_user IS NULL):
SELECT 
  e.id_entrepot,
  e.ville || ' - ' || e.adresse AS entrepot_name
FROM entrepots e
WHERE e.id_user IS NULL;

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Fix completed!
PROMPT ========================================
PROMPT 
PROMPT All entrepots with gestionnaires should now have id_user set.
PROMPT The first gestionnaire assigned to each entrepot has been set as the manager.


