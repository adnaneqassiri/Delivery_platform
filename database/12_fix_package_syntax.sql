--------------------------------------------------
-- FIX: Package syntax error
-- Recreate just the p_marquer_colis_recuperee procedure
-- This avoids potential file encoding issues
--------------------------------------------------

-- Drop and recreate the package body
CREATE OR REPLACE PACKAGE BODY pkg_logitrack AS

  FUNCTION f_role(p_id_user NUMBER) RETURN VARCHAR2 IS
    v_role VARCHAR2(20);
  BEGIN
    SELECT role INTO v_role FROM utilisateurs WHERE id_utilisateur = p_id_user AND actif = 1;
    RETURN v_role;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END;

  PROCEDURE p_creer_utilisateur(
    p_nom  VARCHAR2,
    p_pwd  VARCHAR2,
    p_role VARCHAR2,
    p_cin  VARCHAR2,
    p_id   OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO utilisateurs(nom_utilisateur, mot_de_passe, role, cin)
    VALUES (p_nom, p_pwd, p_role, p_cin)
    RETURNING id_utilisateur INTO p_id;
  END;

  PROCEDURE p_login(
    p_nom  VARCHAR2,
    p_pwd  VARCHAR2,
    p_id   OUT NUMBER,
    p_role OUT VARCHAR2
  ) AS
  BEGIN
    SELECT id_utilisateur, role
    INTO p_id, p_role
    FROM utilisateurs
    WHERE nom_utilisateur = p_nom
      AND mot_de_passe = p_pwd
      AND actif = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_id := 0;
      p_role := NULL;
  END;

  PROCEDURE p_creer_entrepot(
    p_adresse VARCHAR2,
    p_ville   VARCHAR2,
    p_tel     VARCHAR2,
    p_id_user NUMBER,
    p_id      OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO entrepots(adresse, ville, telephone, id_user)
    VALUES (p_adresse, p_ville, p_tel, p_id_user)
    RETURNING id_entrepot INTO p_id;
  END;

  PROCEDURE p_creer_vehicule(
    p_immatriculation VARCHAR2,
    p_type            VARCHAR2,
    p_id_entrepot     NUMBER,
    p_id              OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO vehicules(immatriculation, type_vehicule, id_entrepot)
    VALUES (p_immatriculation, p_type, p_id_entrepot)
    RETURNING id_vehicule INTO p_id;
  END;

  PROCEDURE p_changer_entrepot_vehicule(
    p_id_vehicule NUMBER,
    p_id_entrepot NUMBER,
    p_id_user     NUMBER
  ) AS
    v_role VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('LIVREUR','GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acces refuse: role non autorise');
    END IF;

    UPDATE vehicules
    SET id_entrepot = p_id_entrepot
    WHERE id_vehicule = p_id_vehicule;
  END;

  PROCEDURE p_creer_client(
    p_prenom VARCHAR2,
    p_nom    VARCHAR2,
    p_cin    VARCHAR2,
    p_tel    VARCHAR2,
    p_email  VARCHAR2,
    p_adresse VARCHAR2,
    p_id_gestionnaire NUMBER,
    p_id     OUT NUMBER
  ) AS
    v_role VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_gestionnaire);
    IF v_role NOT IN ('GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20002, 'Seul un gestionnaire/admin peut ajouter un client');
    END IF;

    INSERT INTO clients(prenom, nom, cin, telephone, email, adresse, id_gestionnaire_ajout)
    VALUES (p_prenom, p_nom, p_cin, p_tel, p_email, p_adresse, p_id_gestionnaire)
    RETURNING id_client INTO p_id;
  END;

  PROCEDURE p_creer_combinaisons_livraisons AS
  BEGIN
    FOR src IN (SELECT id_entrepot FROM entrepots) LOOP
      FOR dest IN (SELECT id_entrepot FROM entrepots WHERE id_entrepot <> src.id_entrepot) LOOP
        INSERT INTO livraisons(id_entrepot_source, id_entrepot_destination, statut, date_creation)
        VALUES (src.id_entrepot, dest.id_entrepot, 'CREEE', SYSTIMESTAMP);
      END LOOP;
    END LOOP;
  END;

  PROCEDURE p_prendre_livraison(
    p_id_livraison NUMBER,
    p_id_livreur   NUMBER,
    p_id_vehicule  NUMBER
  ) AS
    v_role VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_livreur);
    IF v_role <> 'LIVREUR' THEN
      RAISE_APPLICATION_ERROR(-20003, 'Seul un livreur peut prendre une livraison');
    END IF;

    UPDATE livraisons
    SET id_livreur = p_id_livreur,
        id_vehicule = p_id_vehicule,
        statut = 'EN_COURS'
    WHERE id_livraison = p_id_livraison
      AND statut = 'CREEE';
  END;

  PROCEDURE p_livrer_livraison(
    p_id_livraison NUMBER,
    p_id_user      NUMBER
  ) AS
    v_role VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('LIVREUR','GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20004, 'Acces refuse');
    END IF;

    UPDATE livraisons
    SET statut = 'LIVREE'
    WHERE id_livraison = p_id_livraison
      AND statut = 'EN_COURS';
  END;

  PROCEDURE p_modifier_statut_livraison(
    p_id_livraison NUMBER,
    p_statut       VARCHAR2,
    p_id_user      NUMBER
  ) AS
    v_role VARCHAR2(20);
    v_old  VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20005, 'Seul un gestionnaire/admin peut modifier statut livraison');
    END IF;

    SELECT statut INTO v_old FROM livraisons WHERE id_livraison = p_id_livraison;

    UPDATE livraisons
    SET statut = p_statut
    WHERE id_livraison = p_id_livraison;

    INSERT INTO historique_statut_livraisons(id_livraison, statut_avant, statut_apres, id_utilisateur)
    VALUES (p_id_livraison, v_old, p_statut, p_id_user);
  END;

  PROCEDURE p_ajouter_colis(
    p_id_client               NUMBER,
    p_poids                   NUMBER,
    p_type                    VARCHAR2,
    p_receiver_cin            VARCHAR2,
    p_ville_destination       VARCHAR2,
    p_id_entrepot_localisation NUMBER,
    p_id_user                 NUMBER,
    p_id_colis                OUT NUMBER
  ) AS
    v_role VARCHAR2(20);
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20006, 'Seul gestionnaire/admin peut ajouter colis');
    END IF;

    INSERT INTO colis(
      id_client, poids, type_colis,
      receiver_cin, ville_destination, id_entrepot_localisation, statut
    ) VALUES (
      p_id_client, p_poids, p_type,
      p_receiver_cin, p_ville_destination, p_id_entrepot_localisation, 'ENREGISTRE'
    )
    RETURNING id_colis INTO p_id_colis;

    INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
    VALUES (p_id_colis, NULL, 'ENREGISTRE', p_id_user);
  END;

  PROCEDURE p_modifier_statut_colis(
    p_id_colis NUMBER,
    p_statut   VARCHAR2,
    p_id_user  NUMBER
  ) AS
    v_role VARCHAR2(20);
    v_old  VARCHAR2(20);
    v_id_entrepot_user NUMBER;
    v_id_entrepot_colis NUMBER;
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20007, 'Seul gestionnaire/admin peut modifier statut colis');
    END IF;

    -- Get colis info
    SELECT statut, id_entrepot_localisation INTO v_old, v_id_entrepot_colis
    FROM colis WHERE id_colis = p_id_colis;

    -- For gestionnaire: check if they can modify this colis
    IF v_role = 'GESTIONNAIRE' THEN
      BEGIN
        SELECT id_entrepot INTO v_id_entrepot_user
        FROM utilisateurs
        WHERE id_utilisateur = p_id_user;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20010, 'Gestionnaire must be assigned to an entrepot');
      END;
      
      IF v_id_entrepot_user IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Gestionnaire must be assigned to an entrepot');
      END IF;
      
      -- Gestionnaire can only modify colis:
      -- 1. Sent from their entrepot (not yet delivered)
      -- 2. OR delivered to their entrepot (for marking as recovered)
      IF NOT (
        (v_id_entrepot_colis = v_id_entrepot_user AND v_old != 'LIVRE' AND v_old != 'RECUPEREE')
        OR
        (v_id_entrepot_colis = v_id_entrepot_user AND v_old = 'LIVRE' AND p_statut = 'RECUPEREE')
      ) THEN
        RAISE_APPLICATION_ERROR(-20011, 'Vous ne pouvez modifier que les colis de votre entrepot');
      END IF;
    END IF;

    UPDATE colis
    SET statut = p_statut
    WHERE id_colis = p_id_colis;

    INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
    VALUES (p_id_colis, v_old, p_statut, p_id_user);
  END;

  PROCEDURE p_marquer_colis_recuperee(
    p_receiver_cin VARCHAR2,
    p_id_user      NUMBER
  ) AS
    v_role VARCHAR2(20);
    v_id_entrepot NUMBER;
    v_count NUMBER := 0;
  BEGIN
    v_role := f_role(p_id_user);
    IF v_role NOT IN ('GESTIONNAIRE','ADMIN') THEN
      RAISE_APPLICATION_ERROR(-20008, 'Seul gestionnaire/admin peut marquer recuperee');
    END IF;
    
    -- Get user's entrepot (for gestionnaire)
    IF v_role = 'GESTIONNAIRE' THEN
      BEGIN
        SELECT id_entrepot INTO v_id_entrepot
        FROM utilisateurs
        WHERE id_utilisateur = p_id_user;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20010, 'Gestionnaire must be assigned to an entrepot');
      END;
      
      IF v_id_entrepot IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Gestionnaire must be assigned to an entrepot');
      END IF;
    END IF;

    -- Update all colis with matching CIN (case-insensitive, trimmed) and LIVRE status
    -- For gestionnaire: only colis delivered to their entrepot
    -- For admin: all colis
    FOR r IN (
      SELECT c.id_colis, c.statut, c.id_entrepot_localisation
      FROM colis c
      WHERE UPPER(TRIM(c.receiver_cin)) = UPPER(TRIM(p_receiver_cin))
        AND c.statut = 'LIVRE'
        AND (
          v_role = 'ADMIN' 
          OR (v_role = 'GESTIONNAIRE' AND c.id_entrepot_localisation = v_id_entrepot)
        )
    ) LOOP
      UPDATE colis
      SET statut = 'RECUPEREE'
      WHERE id_colis = r.id_colis;

      INSERT INTO historique_statut_colis(id_colis, statut_avant, statut_apres, id_utilisateur)
      VALUES (r.id_colis, 'LIVRE', 'RECUPEREE', p_id_user);
      
      v_count := v_count + 1;
    END LOOP;
    
    -- Raise error if no colis found
    IF v_count = 0 THEN
      IF v_role = 'GESTIONNAIRE' THEN
        RAISE_APPLICATION_ERROR(-20009, 'Aucun colis trouve avec CIN ' || p_receiver_cin || ' et statut LIVRE dans votre entrepot');
      ELSE
        RAISE_APPLICATION_ERROR(-20009, 'Aucun colis trouve avec CIN ' || p_receiver_cin || ' et statut LIVRE');
      END IF;
    END IF;
  END;

  PROCEDURE p_get_kpis(p_cur OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_cur FOR
      SELECT * FROM v_kpi_dashboard;
  END;

END pkg_logitrack;
/

COMMIT;

PROMPT Package body recreated successfully!

