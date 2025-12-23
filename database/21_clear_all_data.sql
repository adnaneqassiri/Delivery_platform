--------------------------------------------------
-- CLEAR ALL DATA
-- Run this script to delete all data from all tables
-- Tables structure will remain intact
-- Use this to start fresh for debugging
--------------------------------------------------

-- Disable foreign key constraints temporarily to handle circular references
-- (utilisateurs <-> entrepots have circular FK dependencies)
BEGIN
  -- Disable all foreign key constraints
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_livraisons DISABLE CONSTRAINT fk_hl_liv';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_livraisons DISABLE CONSTRAINT fk_hl_user';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_colis DISABLE CONSTRAINT fk_hc_colis';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_colis DISABLE CONSTRAINT fk_hc_user';
  EXECUTE IMMEDIATE 'ALTER TABLE colis DISABLE CONSTRAINT fk_colis_client';
  EXECUTE IMMEDIATE 'ALTER TABLE colis DISABLE CONSTRAINT fk_colis_livraison';
  EXECUTE IMMEDIATE 'ALTER TABLE colis DISABLE CONSTRAINT fk_colis_entrepot_loc';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons DISABLE CONSTRAINT fk_liv_source';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons DISABLE CONSTRAINT fk_liv_dest';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons DISABLE CONSTRAINT fk_liv_livreur';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons DISABLE CONSTRAINT fk_liv_vehicule';
  EXECUTE IMMEDIATE 'ALTER TABLE vehicules DISABLE CONSTRAINT fk_vehicule_entrepot';
  EXECUTE IMMEDIATE 'ALTER TABLE clients DISABLE CONSTRAINT fk_client_gestionnaire_ajout';
  EXECUTE IMMEDIATE 'ALTER TABLE entrepots DISABLE CONSTRAINT fk_entrepot_user';
  EXECUTE IMMEDIATE 'ALTER TABLE utilisateurs DISABLE CONSTRAINT fk_user_entrepot';
EXCEPTION
  WHEN OTHERS THEN
    -- Some constraints might not exist, continue anyway
    NULL;
END;
/

-- Delete from history tables first (they reference other tables)
DELETE FROM historique_statut_livraisons;
DELETE FROM historique_statut_colis;

-- Delete from main tables
DELETE FROM colis;
DELETE FROM livraisons;
DELETE FROM vehicules;
DELETE FROM clients;
-- Delete entrepots and utilisateurs (circular dependency handled by disabled constraints)
DELETE FROM entrepots;
DELETE FROM utilisateurs;

-- Re-enable all foreign key constraints
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE utilisateurs ENABLE CONSTRAINT fk_user_entrepot';
  EXECUTE IMMEDIATE 'ALTER TABLE entrepots ENABLE CONSTRAINT fk_entrepot_user';
  EXECUTE IMMEDIATE 'ALTER TABLE clients ENABLE CONSTRAINT fk_client_gestionnaire_ajout';
  EXECUTE IMMEDIATE 'ALTER TABLE vehicules ENABLE CONSTRAINT fk_vehicule_entrepot';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons ENABLE CONSTRAINT fk_liv_vehicule';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons ENABLE CONSTRAINT fk_liv_livreur';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons ENABLE CONSTRAINT fk_liv_dest';
  EXECUTE IMMEDIATE 'ALTER TABLE livraisons ENABLE CONSTRAINT fk_liv_source';
  EXECUTE IMMEDIATE 'ALTER TABLE colis ENABLE CONSTRAINT fk_colis_entrepot_loc';
  EXECUTE IMMEDIATE 'ALTER TABLE colis ENABLE CONSTRAINT fk_colis_livraison';
  EXECUTE IMMEDIATE 'ALTER TABLE colis ENABLE CONSTRAINT fk_colis_client';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_colis ENABLE CONSTRAINT fk_hc_user';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_colis ENABLE CONSTRAINT fk_hc_colis';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_livraisons ENABLE CONSTRAINT fk_hl_user';
  EXECUTE IMMEDIATE 'ALTER TABLE historique_statut_livraisons ENABLE CONSTRAINT fk_hl_liv';
EXCEPTION
  WHEN OTHERS THEN
    -- Some constraints might not exist, continue anyway
    NULL;
END;
/

-- Reset sequences to start from 1
-- Oracle doesn't support RESTART, so we use INCREMENT BY to reset
DECLARE
  PROCEDURE reset_sequence(p_seq_name VARCHAR2) IS
    v_current_val NUMBER;
    v_increment NUMBER;
  BEGIN
    -- Get current value
    EXECUTE IMMEDIATE 'SELECT ' || p_seq_name || '.NEXTVAL FROM DUAL' INTO v_current_val;
    
    -- Calculate increment needed to go back to 1
    IF v_current_val > 1 THEN
      v_increment := -(v_current_val - 1);
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY ' || v_increment;
      EXECUTE IMMEDIATE 'SELECT ' || p_seq_name || '.NEXTVAL FROM DUAL' INTO v_current_val;
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY 1';
    END IF;
  END;
BEGIN
  reset_sequence('seq_hist_liv');
  reset_sequence('seq_hist_colis');
  reset_sequence('seq_colis');
  reset_sequence('seq_livraisons');
  reset_sequence('seq_clients');
  reset_sequence('seq_vehicules');
  reset_sequence('seq_entrepots');
  reset_sequence('seq_utilisateurs');
END;
/

COMMIT;

PROMPT All data cleared successfully! All tables are now empty and sequences reset.

