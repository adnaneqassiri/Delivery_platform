--------------------------------------------------
-- CREATE USER IN PDB (Pluggable Database)
-- Oracle XE Docker uses PDB by default
-- Run this as SYSTEM user connected to PDB
--------------------------------------------------

PROMPT ========================================
PROMPT Creating LogiTrack User in PDB
PROMPT ========================================
PROMPT 

-- Switch to PDB if needed (for Oracle XE Docker)
ALTER SESSION SET CONTAINER = XEPDB1;

-- Drop user if exists
BEGIN
   EXECUTE IMMEDIATE 'DROP USER logitrack CASCADE';
   DBMS_OUTPUT.PUT_LINE('User dropped');
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -1918 THEN
         DBMS_OUTPUT.PUT_LINE('User does not exist');
      ELSE
         RAISE;
      END IF;
END;
/

-- Create user
PROMPT Creating user LOGITRACK in PDB...
CREATE USER logitrack IDENTIFIED BY logitrack123;

-- Grant privileges
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

-- Unlock account
ALTER USER logitrack ACCOUNT UNLOCK;

PROMPT 
PROMPT ========================================
PROMPT User LOGITRACK created in PDB!
PROMPT ========================================
PROMPT 
PROMPT Try connecting with:
PROMPT   Username: logitrack
PROMPT   Password: logitrack123
PROMPT   Service: XEPDB1 (instead of XE)
PROMPT 

COMMIT;

