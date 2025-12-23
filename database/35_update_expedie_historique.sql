--------------------------------------------------
-- UPDATE: historique_statut_colis - fix EXPEDIE status
-- Update historical records that reference EXPEDIE
--------------------------------------------------

PROMPT ========================================
PROMPT Updating historique_statut_colis
PROMPT ========================================

-- Update statut_avant
UPDATE historique_statut_colis SET statut_avant = 'ENVOYEE' WHERE statut_avant = 'EXPEDIE';
PROMPT Updated statut_avant EXPEDIE -> ENVOYEE: &SQL%ROWCOUNT rows

-- Update statut_apres
UPDATE historique_statut_colis SET statut_apres = 'ENVOYEE' WHERE statut_apres = 'EXPEDIE';
PROMPT Updated statut_apres EXPEDIE -> ENVOYEE: &SQL%ROWCOUNT rows

COMMIT;

PROMPT 
PROMPT ========================================
PROMPT Historical records updated!
PROMPT ========================================


