--------------------------------------------------
-- FIX: Livreurs count in KPI dashboard
-- The view should use UPPER(TRIM(role)) to handle any whitespace
-- or case issues in the role field
--------------------------------------------------

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

PROMPT KPI view updated to correctly count active livreurs!
PROMPT 
PROMPT The view now uses UPPER(TRIM(role)) to handle any whitespace or case issues.


