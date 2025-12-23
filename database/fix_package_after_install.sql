--------------------------------------------------
-- FIX PACKAGE AFTER INSTALLATION
-- Run this after install.sql if you see package errors
-- This recompiles the package body after views are created
--------------------------------------------------

PROMPT Recompiling package body after views are created...

ALTER PACKAGE pkg_logitrack COMPILE BODY;

-- Check for errors
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name = 'PKG_LOGITRACK';

PROMPT 
PROMPT Package recompiled. Check status above.
PROMPT If STATUS = 'VALID', the package is working correctly.
PROMPT 

