--------------------------------------------------
-- FIX: Clients count in KPI view
-- Ensure it counts all clients correctly
--------------------------------------------------

CREATE OR REPLACE VIEW v_kpi_dashboard AS
SELECT
  (SELECT COUNT(*) FROM colis) AS colis_count,
  (SELECT COUNT(*) FROM livraisons) AS livraisons_count,
  (SELECT NVL(SUM(prix),0) FROM colis WHERE statut IN ('LIVRE','RECUPEREE')) AS chiffre_affaire,
  (SELECT COUNT(*) FROM utilisateurs WHERE role = 'LIVREUR' AND actif = 1) AS livreurs_count,
  (SELECT COUNT(*) FROM entrepots) AS entrepots_count,
  (SELECT COUNT(*) FROM clients) AS clients_count
FROM dual;

COMMIT;

PROMPT KPI view updated!


