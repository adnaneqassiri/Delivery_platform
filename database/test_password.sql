--------------------------------------------------
-- TEST PASSWORD DIRECTLY
-- Run this as SYSTEM user to verify password
--------------------------------------------------

PROMPT Testing password for logitrack user...
PROMPT 

-- Try to connect as logitrack with the password
-- This will show if password is correct
BEGIN
   EXECUTE IMMEDIATE 'ALTER USER logitrack IDENTIFIED BY logitrack123';
   DBMS_OUTPUT.PUT_LINE('Password reset to: logitrack123');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Show user details
SELECT username, account_status, 
       CASE WHEN password IS NULL THEN 'NULL' ELSE 'SET' END as password_status
FROM dba_users 
WHERE username = 'LOGITRACK';

PROMPT 
PROMPT If you can connect in SQL Developer as logitrack/logitrack123,
PROMPT but Node.js cannot, it might be a connection string issue.
PROMPT 

COMMIT;



