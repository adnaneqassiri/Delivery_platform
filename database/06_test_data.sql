--------------------------------------------------
-- TEST DATA
-- Run this script to insert test data
--------------------------------------------------

-- users (note: entrepots must be created first, then we can assign id_entrepot)
-- We'll update id_entrepot after creating entrepots
INSERT INTO utilisateurs(nom_utilisateur, mot_de_passe, role, cin) VALUES ('admin', 'admin123', 'ADMIN', 'AA111111');
INSERT INTO utilisateurs(nom_utilisateur, mot_de_passe, role, cin) VALUES ('gest1', 'gest123', 'GESTIONNAIRE', 'BB222222');
INSERT INTO utilisateurs(nom_utilisateur, mot_de_passe, role, cin) VALUES ('liv1',  'liv123',  'LIVREUR', 'CC333333');

-- entrepots (id_user = gest1 = 2)
INSERT INTO entrepots(adresse, ville, telephone, id_user) VALUES ('123 Rue Principale', 'Casablanca', '0522-123456', 2);
INSERT INTO entrepots(adresse, ville, telephone, id_user) VALUES ('456 Avenue Mohammed V', 'Rabat', '0537-654321', 2);
INSERT INTO entrepots(adresse, ville, telephone, id_user) VALUES ('789 Boulevard Hassan II', 'Marrakech', '0524-789012', 2);

-- Assign entrepot to livreur (liv1 = id 3, assign to entrepot 1)
UPDATE utilisateurs SET id_entrepot = 1 WHERE id_utilisateur = 3;

-- Assign entrepot to gestionnaire (gest1 = id 2, assign to entrepot 1)
UPDATE utilisateurs SET id_entrepot = 1 WHERE id_utilisateur = 2;

-- vehicules
INSERT INTO vehicules(immatriculation, type_vehicule, id_entrepot) VALUES ('CAS-1111', 'PETIT_CAMION', 1);
INSERT INTO vehicules(immatriculation, type_vehicule, id_entrepot) VALUES ('RAB-2222', 'GRAND_CAMION', 2);

-- clients (added by gest1=2)
INSERT INTO clients(prenom, nom, cin, telephone, email, adresse, id_gestionnaire_ajout)
VALUES ('Ahmed', 'Benani', 'CL1111', '0612-345678', 'ahmed@email.com', '10 Rue Test, Casablanca', 2);

INSERT INTO clients(prenom, nom, cin, telephone, email, adresse, id_gestionnaire_ajout)
VALUES ('Fatima', 'Zahra', 'CL2222', '0613-456789', 'fatima@email.com', '20 Av Test, Rabat', 2);

-- create default livraison combinations
BEGIN
  pkg_logitrack.p_creer_combinaisons_livraisons;
END;
/

-- add some colis (auto assign based on localisation source + city destination)
DECLARE
  v_id NUMBER;
BEGIN
  pkg_logitrack.p_ajouter_colis(
    p_id_client => 1,
    p_poids => 2,
    p_type => 'STANDARD',
    p_receiver_cin => 'RCV9000',
    p_ville_destination => 'Rabat',
    p_id_entrepot_localisation => 1,
    p_id_user => 2,
    p_id_colis => v_id
  );

  pkg_logitrack.p_ajouter_colis(
    p_id_client => 2,
    p_poids => 3,
    p_type => 'FRAGILE',
    p_receiver_cin => 'RCV9001',
    p_ville_destination => 'Casablanca',
    p_id_entrepot_localisation => 2,
    p_id_user => 2,
    p_id_colis => v_id
  );
END;
/

COMMIT;

PROMPT Test data inserted successfully!
PROMPT 
PROMPT Default login credentials:
PROMPT   Admin:        username=admin, password=admin123
PROMPT   Gestionnaire: username=gest1, password=gest123
PROMPT   Livreur:      username=liv1,  password=liv123



