--------------------------------------------------
-- CREATE ADMIN USER
-- Run this script to create an admin user with password "123"
--------------------------------------------------

-- Insert admin user
INSERT INTO utilisateurs(
  id_utilisateur,
  nom_utilisateur,
  mot_de_passe,
  role,
  actif,
  date_creation
) VALUES (
  seq_utilisateurs.NEXTVAL,
  'admin',
  '123',
  'ADMIN',
  1,
  SYSTIMESTAMP
);

COMMIT;

PROMPT Admin user created successfully!
PROMPT 
PROMPT Login credentials:
PROMPT   Username: admin
PROMPT   Password: 123
PROMPT 


