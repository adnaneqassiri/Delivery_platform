--------------------------------------------------
-- TEST DATA (CLEAN - Only Admin)
-- Run this script to insert minimal test data
--------------------------------------------------

-- Clean all existing data first
DELETE FROM historique_statut_colis;
DELETE FROM historique_statut_livraisons;
DELETE FROM colis;
DELETE FROM livraisons;
DELETE FROM clients;
DELETE FROM vehicules;
DELETE FROM entrepots;
DELETE FROM utilisateurs;

-- Reset sequences (Oracle syntax: drop and recreate)
DECLARE
  v_nextval NUMBER;
BEGIN
  -- Reset seq_utilisateurs
  SELECT seq_utilisateurs.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_utilisateurs';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_utilisateurs START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_entrepots
  SELECT seq_entrepots.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_entrepots';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_entrepots START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_vehicules
  SELECT seq_vehicules.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_vehicules';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_vehicules START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_clients
  SELECT seq_clients.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_clients';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_clients START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_livraisons
  SELECT seq_livraisons.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_livraisons';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_livraisons START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_colis
  SELECT seq_colis.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_colis';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_colis START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_hist_colis
  SELECT seq_hist_colis.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_hist_colis';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_hist_colis START WITH 1 INCREMENT BY 1';
  
  -- Reset seq_hist_liv
  SELECT seq_hist_liv.NEXTVAL INTO v_nextval FROM dual;
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_hist_liv';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_hist_liv START WITH 1 INCREMENT BY 1';
END;
/

-- Create only one admin user with password '123'
INSERT INTO utilisateurs(nom_utilisateur, mot_de_passe, role, cin) 
VALUES ('admin', '123', 'ADMIN', 'ADMIN001');

COMMIT;

PROMPT Test data cleaned and reset successfully!
PROMPT 
PROMPT Default login credentials:
PROMPT   Admin: username=admin, password=123
PROMPT 
PROMPT You can now create everything from scratch using the admin account.



