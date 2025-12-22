--------------------------------------------------
-- TEST CONNECTION AS LOGITRACK USER
-- Run this script while connected as logitrack user
-- If this works, the backend should work too
--------------------------------------------------

PROMPT Testing connection as logitrack user...
PROMPT 

SELECT 'Connected successfully!' AS status FROM DUAL;
SELECT USER AS current_user FROM DUAL;
SELECT COUNT(*) AS table_count FROM user_tables;

PROMPT 
PROMPT If you see the above results, connection is working!
PROMPT If you get errors, the user needs to be fixed.



