--------------------------------------------------
-- DROP ALL OBJECTS
-- Run this script to drop all database objects
-- Use this if you need to start fresh
--------------------------------------------------

-- Drop in reverse order of dependencies

-- Drop Views
DROP VIEW v_kpi_dashboard;
DROP VIEW v_vehicules_entrepots;
DROP VIEW v_colis_details;
DROP VIEW v_livraisons_details;

-- Drop Package
DROP PACKAGE BODY pkg_logitrack;
DROP PACKAGE pkg_logitrack;

-- Drop Triggers
DROP TRIGGER trg_livraison_arrivee;
DROP TRIGGER trg_livraison_depart;
DROP TRIGGER trg_colis_annulation_unassign;
DROP TRIGGER trg_colis_assign_price;
DROP TRIGGER trg_hist_liv_id;
DROP TRIGGER trg_hist_colis_id;
DROP TRIGGER trg_colis_id;
DROP TRIGGER trg_livraisons_id;
DROP TRIGGER trg_clients_id;
DROP TRIGGER trg_vehicules_id;
DROP TRIGGER trg_entrepots_id;
DROP TRIGGER trg_utilisateurs_id;

-- Drop Tables
DROP TABLE historique_statut_livraisons;
DROP TABLE historique_statut_colis;
DROP TABLE colis;
DROP TABLE livraisons;
DROP TABLE vehicules;
DROP TABLE clients;
DROP TABLE entrepots;
DROP TABLE utilisateurs;

-- Drop Sequences
DROP SEQUENCE seq_hist_liv;
DROP SEQUENCE seq_hist_colis;
DROP SEQUENCE seq_colis;
DROP SEQUENCE seq_livraisons;
DROP SEQUENCE seq_clients;
DROP SEQUENCE seq_vehicules;
DROP SEQUENCE seq_entrepots;
DROP SEQUENCE seq_utilisateurs;

COMMIT;

PROMPT All objects dropped successfully!



