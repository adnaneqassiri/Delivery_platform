--------------------------------------------------
-- FIX/RECREATE LOGITRACK USER
-- Run this as SYSTEM user
--------------------------------------------------

PROMPT ========================================
PROMPT Fixing LogiTrack User
PROMPT ========================================
PROMPT 

-- Drop user if exists
BEGIN
   EXECUTE IMMEDIATE 'DROP USER logitrack CASCADE';
   DBMS_OUTPUT.PUT_LINE('User dropped');
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -1918 THEN
         DBMS_OUTPUT.PUT_LINE('User does not exist, creating new...');
      ELSE
         RAISE;
      END IF;
END;
/

-- Create user
PROMPT Creating user LOGITRACK...
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

-- Unlock account (in case it was locked)
ALTER USER logitrack ACCOUNT UNLOCK;

PROMPT 
PROMPT ========================================
PROMPT User LOGITRACK fixed!
PROMPT ========================================
PROMPT 
PROMPT Credentials:
PROMPT   Username: logitrack
PROMPT   Password: logitrack123
PROMPT 
PROMPT Next: Connect as logitrack and run @install.sql
PROMPT 

COMMIT;



