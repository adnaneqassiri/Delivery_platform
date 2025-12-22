--------------------------------------------------
-- VERIFY AND FIX LOGITRACK USER
-- Run this as SYSTEM user
--------------------------------------------------

PROMPT ========================================
PROMPT Verifying LogiTrack User
PROMPT ========================================
PROMPT 

-- Check if user exists
SELECT username, account_status, created, expiry_date, lock_date
FROM dba_users 
WHERE username = 'LOGITRACK';

PROMPT 
PROMPT Fixing user if needed...
PROMPT 

-- Unlock account
ALTER USER logitrack ACCOUNT UNLOCK;

-- Reset password (force)
ALTER USER logitrack IDENTIFIED BY logitrack123;

-- Ensure privileges
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
PROMPT User should now work!
PROMPT ========================================
PROMPT 
PROMPT Try connecting with:
PROMPT   Username: logitrack
PROMPT   Password: logitrack123
PROMPT 

COMMIT;



