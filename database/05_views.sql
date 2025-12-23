--------------------------------------------------
-- VIEWS
-- Run this script to create all views
--------------------------------------------------

CREATE OR REPLACE VIEW v_livraisons_details AS
SELECT
  l.id_livraison,
  e1.ville || ' - ' || e1.adresse AS source,
  e2.ville || ' - ' || e2.adresse AS destination,
  u.nom_utilisateur AS livreur,
  v.immatriculation AS vehicule,
  l.statut,
  l.date_creation,
  l.date_livraison,
  COUNT(c.id_colis) AS nb_colis
FROM livraisons l
JOIN entrepots e1 ON l.id_entrepot_source = e1.id_entrepot
JOIN entrepots e2 ON l.id_entrepot_destination = e2.id_entrepot
LEFT JOIN utilisateurs u ON l.id_livreur = u.id_utilisateur
LEFT JOIN vehicules v ON l.id_vehicule = v.id_vehicule
LEFT JOIN colis c ON l.id_livraison = c.id_livraison
GROUP BY l.id_livraison, e1.ville, e1.adresse, e2.ville, e2.adresse,
         u.nom_utilisateur, v.immatriculation, l.statut,
         l.date_creation, l.date_livraison;

CREATE OR REPLACE VIEW v_colis_details AS
SELECT
  c.id_colis,
  cl.nom || ' ' || cl.prenom AS client,
  c.poids,
  c.type_colis,
  c.prix,
  c.receiver_cin,
  c.ville_destination,
  c.statut,
  l.id_livraison,
  -- Calculate route: if livraison exists, use it; otherwise use entrepot_localisation and ville_destination
  CASE 
    WHEN l.id_livraison IS NOT NULL THEN
      e1.ville || ' -> ' || e2.ville
    WHEN c.id_entrepot_localisation IS NOT NULL AND c.ville_destination IS NOT NULL THEN
      el.ville || ' -> ' || c.ville_destination
    ELSE
      NULL
  END AS trajet,
  el.ville || ' - ' || el.adresse AS localisation_entrepot
FROM colis c
LEFT JOIN clients cl ON c.id_client = cl.id_client
LEFT JOIN livraisons l ON c.id_livraison = l.id_livraison
LEFT JOIN entrepots e1 ON l.id_entrepot_source = e1.id_entrepot
LEFT JOIN entrepots e2 ON l.id_entrepot_destination = e2.id_entrepot
LEFT JOIN entrepots el ON c.id_entrepot_localisation = el.id_entrepot;

CREATE OR REPLACE VIEW v_vehicules_entrepots AS
SELECT
  v.id_vehicule,
  v.immatriculation,
  v.type_vehicule,
  v.statut AS statut_vehicule,
  e.ville || ' - ' || e.adresse AS entrepot_actuel
FROM vehicules v
LEFT JOIN entrepots e ON v.id_entrepot = e.id_entrepot;

-- KPI view
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

PROMPT Views created successfully!



