--------------------------------------------------
-- TABLES
-- Run this script to create all tables
--------------------------------------------------

-- UTILISATEURS (id_entrepot will be added after entrepots table is created)
CREATE TABLE utilisateurs (
  id_utilisateur   NUMBER PRIMARY KEY,
  nom_utilisateur  VARCHAR2(50) NOT NULL UNIQUE,
  mot_de_passe     VARCHAR2(100) NOT NULL,
  cin              VARCHAR2(20) UNIQUE,
  role             VARCHAR2(20) NOT NULL
      CHECK (role IN ('ADMIN','GESTIONNAIRE','LIVREUR')),
  actif            NUMBER(1) DEFAULT 1 CHECK (actif IN (0,1)),
  date_creation    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ENTREPOTS (add id_user gestionnaire responsable)
CREATE TABLE entrepots (
  id_entrepot    NUMBER PRIMARY KEY,
  adresse        VARCHAR2(200) NOT NULL,
  ville          VARCHAR2(100) NOT NULL,
  telephone      VARCHAR2(20),
  id_user        NUMBER, -- gestionnaire responsable (manager of warehouse)
  date_creation  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_entrepot_user
    FOREIGN KEY (id_user) REFERENCES utilisateurs(id_utilisateur)
);

-- VEHICULES (type only petit/grand camion)
CREATE TABLE vehicules (
  id_vehicule       NUMBER PRIMARY KEY,
  immatriculation   VARCHAR2(20) UNIQUE NOT NULL,
  type_vehicule     VARCHAR2(20) NOT NULL
      CHECK (type_vehicule IN ('PETIT_CAMION','GRAND_CAMION')),
  statut            VARCHAR2(20) DEFAULT 'DISPONIBLE'
      CHECK (statut IN ('DISPONIBLE','EN_UTILISATION','MAINTENANCE')),
  id_entrepot       NUMBER,
  date_creation     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vehicule_entrepot
    FOREIGN KEY (id_entrepot) REFERENCES entrepots(id_entrepot)
);

-- CLIENTS (add CIN + id_gestionnaire_ajout)
CREATE TABLE clients (
  id_client            NUMBER PRIMARY KEY,
  prenom               VARCHAR2(50),
  nom                  VARCHAR2(50),
  cin                  VARCHAR2(20) UNIQUE,
  telephone            VARCHAR2(20),
  email                VARCHAR2(100),
  adresse              VARCHAR2(200),
  id_gestionnaire_ajout NUMBER, -- who added them
  date_creation        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_client_gestionnaire_ajout
    FOREIGN KEY (id_gestionnaire_ajout) REFERENCES utilisateurs(id_utilisateur)
);

-- LIVRAISONS
CREATE TABLE livraisons (
  id_livraison          NUMBER PRIMARY KEY,
  id_entrepot_source    NUMBER NOT NULL,
  id_entrepot_destination NUMBER NOT NULL,
  id_livreur            NUMBER,
  id_vehicule           NUMBER,
  statut                VARCHAR2(20) DEFAULT 'CREEE'
      CHECK (statut IN ('CREEE','EN_COURS','LIVREE','ANNULEE')),
  date_creation         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_livraison        DATE,
  CONSTRAINT fk_liv_source FOREIGN KEY (id_entrepot_source) REFERENCES entrepots(id_entrepot),
  CONSTRAINT fk_liv_dest   FOREIGN KEY (id_entrepot_destination) REFERENCES entrepots(id_entrepot),
  CONSTRAINT fk_liv_livreur FOREIGN KEY (id_livreur) REFERENCES utilisateurs(id_utilisateur),
  CONSTRAINT fk_liv_vehicule FOREIGN KEY (id_vehicule) REFERENCES vehicules(id_vehicule)
);

-- COLIS (price calculated, poids min 1kg, receiver cin, ville destination,
-- assigned automatically to livraison, id_entrepot_localisation, status includes RECUPEREE)
CREATE TABLE colis (
  id_colis                NUMBER PRIMARY KEY,
  id_client               NUMBER,
  id_livraison             NUMBER,
  poids                   NUMBER NOT NULL CHECK (poids >= 1),
  type_colis              VARCHAR2(20) DEFAULT 'STANDARD'
      CHECK (type_colis IN ('STANDARD','FRAGILE')),
  prix                    NUMBER(10,2), -- computed
  receiver_cin            VARCHAR2(20) NOT NULL,
  ville_destination       VARCHAR2(100) NOT NULL,
  id_entrepot_localisation NUMBER, -- where it currently is
  statut                  VARCHAR2(20) DEFAULT 'ENREGISTRE'
      CHECK (statut IN ('ENREGISTRE','EN_COURS','LIVRE','RECEPTIONNEE','ANNULE','RECUPEREE')),
  date_creation           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_colis_client FOREIGN KEY (id_client) REFERENCES clients(id_client),
  CONSTRAINT fk_colis_livraison FOREIGN KEY (id_livraison) REFERENCES livraisons(id_livraison),
  CONSTRAINT fk_colis_entrepot_loc FOREIGN KEY (id_entrepot_localisation) REFERENCES entrepots(id_entrepot)
);

--------------------------------------------------
-- HISTORIQUES
--------------------------------------------------

-- HISTORIQUE COLIS (avant/apres)
CREATE TABLE historique_statut_colis (
  id_history       NUMBER PRIMARY KEY,
  id_colis         NUMBER,
  statut_avant     VARCHAR2(20),
  statut_apres     VARCHAR2(20),
  date_changement  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_utilisateur   NUMBER,
  CONSTRAINT fk_hc_colis FOREIGN KEY (id_colis) REFERENCES colis(id_colis),
  CONSTRAINT fk_hc_user  FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(id_utilisateur)
);

-- HISTORIQUE LIVRAISONS (avant/apres)
CREATE TABLE historique_statut_livraisons (
  id_history       NUMBER PRIMARY KEY,
  id_livraison     NUMBER,
  statut_avant     VARCHAR2(20),
  statut_apres     VARCHAR2(20),
  date_changement  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_utilisateur   NUMBER NULL,
  CONSTRAINT fk_hl_liv FOREIGN KEY (id_livraison) REFERENCES livraisons(id_livraison),
  CONSTRAINT fk_hl_user FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(id_utilisateur)
);

-- Add id_entrepot column to utilisateurs (after entrepots table exists)
ALTER TABLE utilisateurs ADD id_entrepot NUMBER;

-- Add foreign key constraint for id_entrepot
ALTER TABLE utilisateurs 
ADD CONSTRAINT fk_user_entrepot 
FOREIGN KEY (id_entrepot) REFERENCES entrepots(id_entrepot);

COMMENT ON COLUMN utilisateurs.id_entrepot IS 'Entrepot assigned to livreur/gestionnaire';

-- Constraint: Un gestionnaire ne peut gérer qu'un seul entrepot
-- (id_user dans entrepots doit être unique - un gestionnaire = un entrepot)
CREATE UNIQUE INDEX idx_entrepot_unique_gestionnaire 
ON entrepots(id_user);

COMMIT;

PROMPT Tables created successfully!

