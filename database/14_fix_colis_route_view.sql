--------------------------------------------------
-- FIX: Update v_colis_details view to show route even when colis
-- is not yet assigned to a livraison
-- The route should be calculated from entrepot_localisation -> ville_destination
--------------------------------------------------

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

COMMIT;

PROMPT View v_colis_details updated to show route for unassigned colis!



