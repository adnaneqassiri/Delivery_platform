-- Test package compilation
SET SERVEROUTPUT ON;

-- Drop and recreate package to ensure clean compilation
DROP PACKAGE BODY pkg_logitrack;
DROP PACKAGE pkg_logitrack;

-- Recreate package spec
@04_package.sql

-- Check for errors
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name = 'PKG_LOGITRACK';

SELECT line, position, text 
FROM user_errors 
WHERE name = 'PKG_LOGITRACK' 
ORDER BY sequence;
