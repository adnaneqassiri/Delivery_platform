--------------------------------------------------
-- REINSTALL DATABASE FROM SCRATCH
-- This script drops everything and reinstalls fresh
-- Usage: @reinstall.sql
--------------------------------------------------

PROMPT ========================================
PROMPT LogiTrack Database - Complete Reinstall
PROMPT ========================================
PROMPT 
PROMPT WARNING: This will delete ALL existing data!
PROMPT Press Ctrl+C to cancel, or Enter to continue...
PAUSE

PROMPT 
PROMPT Step 0: Dropping all existing objects...
@00_drop_all.sql

PROMPT 
PROMPT Step 1: Creating user (logitrack IDENTIFIED BY logitrack123)...
@create_user_pdb.sql

PROMPT 
PROMPT Step 2: Installing fresh database...
@install.sql

PROMPT 
PROMPT ========================================
PROMPT Reinstallation completed successfully!
PROMPT ========================================
PROMPT 
PROMPT You can now use the application with:
PROMPT   logitrack_db:    database=logitrack, password=logitrack123
PROMPT   Admin:        username=admin, password=123
PROMPT 



