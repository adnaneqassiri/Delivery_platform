--------------------------------------------------
-- FIX: Mark colis as recovered by CIN
-- Issues fixed:
-- 1. Case sensitivity - now uses UPPER(TRIM()) for case-insensitive matching
-- 2. No error if no colis found - now raises error
-- 3. Whitespace handling - trims both sides
--------------------------------------------------

-- Recreate the package body with the fixed procedure
-- Note: This requires the full package body, so we'll use ALTER PACKAGE or recreate
-- The easiest way is to run the full 04_package.sql file which has been updated

-- Alternative: Just recreate the package body (you need all procedures)
-- But since we updated 04_package.sql, just run that file:

PROMPT To apply this fix, run: @database/04_package.sql
PROMPT This will recreate the package body with the fixed p_marquer_colis_recuperee procedure

-- The fix includes:
-- 1. UPPER(TRIM()) for case-insensitive CIN matching
-- 2. Error raised if no colis found
-- 3. Counter to track how many colis were updated

COMMIT;

PROMPT Fix instructions displayed!
