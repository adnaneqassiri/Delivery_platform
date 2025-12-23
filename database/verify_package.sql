-- Verify package status and show errors
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name = 'PKG_LOGITRACK';

-- Show compilation errors
SELECT line, position, text 
FROM user_errors 
WHERE name = 'PKG_LOGITRACK' 
ORDER BY sequence;
