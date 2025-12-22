--------------------------------------------------
-- MASTER INSTALLATION SCRIPT
-- Run this script to install everything in order
-- Usage: @install.sql
--------------------------------------------------

PROMPT ========================================
PROMPT LogiTrack Database Installation
PROMPT ========================================
PROMPT 

PROMPT Step 1: Creating sequences...
@01_sequences.sql

PROMPT 
PROMPT Step 2: Creating tables...
@02_tables.sql

PROMPT 
PROMPT Step 3: Creating triggers...
@03_triggers.sql

PROMPT 
PROMPT Step 4: Creating package...
@04_package.sql

PROMPT 
PROMPT Step 5: Creating views...
@05_views.sql

PROMPT 
PROMPT Step 6: Inserting test data...
@06_test_data.sql

PROMPT 
PROMPT ========================================
PROMPT Installation completed successfully!
PROMPT ========================================
PROMPT 
PROMPT You can now use the application with:
PROMPT   Admin:        username=admin, password=admin123
PROMPT   Gestionnaire: username=gest1, password=gest123
PROMPT   Livreur:      username=liv1,  password=liv123
PROMPT 
