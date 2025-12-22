--------------------------------------------------
-- VERIFY USER EXISTS
-- Run this as SYSTEM user
--------------------------------------------------

PROMPT Checking if logitrack user exists...

SELECT username, account_status, created 
FROM dba_users 
WHERE username = 'LOGITRACK';

PROMPT 
PROMPT If user exists but connection fails, try:
PROMPT 1. Unlock the account: ALTER USER logitrack ACCOUNT UNLOCK;
PROMPT 2. Reset password: ALTER USER logitrack IDENTIFIED BY logitrack123;
PROMPT 3. Grant privileges again (see create_user.sql)



