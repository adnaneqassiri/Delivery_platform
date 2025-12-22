--------------------------------------------------
-- CREATE ORACLE USER FOR LOGITRACK
-- Run this script as SYSTEM or SYS user
-- Usage: sqlplus system/password@database @create_user.sql
--------------------------------------------------

PROMPT ========================================
PROMPT Creating LogiTrack Database User
PROMPT ========================================
PROMPT 

-- Drop user if exists (optional - uncomment if you want to start fresh)
-- DROP USER logitrack CASCADE;

-- Create user
PROMPT Creating user LOGITRACK...
CREATE USER logitrack IDENTIFIED BY logitrack123;

-- Grant basic privileges
PROMPT Granting privileges...
GRANT CONNECT, RESOURCE TO logitrack;
GRANT CREATE SESSION TO logitrack;
GRANT CREATE TABLE TO logitrack;
GRANT CREATE SEQUENCE TO logitrack;
GRANT CREATE TRIGGER TO logitrack;
GRANT CREATE PROCEDURE TO logitrack;
GRANT CREATE VIEW TO logitrack;
GRANT CREATE SYNONYM TO logitrack;
GRANT UNLIMITED TABLESPACE TO logitrack;

PROMPT 
PROMPT ========================================
PROMPT User LOGITRACK created successfully!
PROMPT ========================================
PROMPT 
PROMPT Default credentials:
PROMPT   Username: logitrack
PROMPT   Password: logitrack123
PROMPT 
PROMPT Next steps:
PROMPT   1. Connect as logitrack user
PROMPT   2. Run: @install.sql
PROMPT 
PROMPT Example:
PROMPT   sqlplus logitrack/logitrack123@database @install.sql
PROMPT 

COMMIT;

