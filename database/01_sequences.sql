--------------------------------------------------
-- SEQUENCES
-- Run this script to create all sequences
--------------------------------------------------

CREATE SEQUENCE seq_utilisateurs START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_entrepots    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_vehicules    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_clients      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_livraisons   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_colis        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_hist_colis   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_hist_liv     START WITH 1 INCREMENT BY 1;

COMMIT;

PROMPT Sequences created successfully!



