--------------------------------------------------
-- ADD ENTREPOT FIELD TO UTILISATEURS (SAFE VERSION)
-- This script safely adds id_entrepot column if it doesn't exist
-- Can be run multiple times without error
--------------------------------------------------

-- Check if column exists and add if not
DECLARE
  v_count NUMBER;
BEGIN
  -- Check if column exists
  SELECT COUNT(*)
  INTO v_count
  FROM user_tab_columns
  WHERE table_name = 'UTILISATEURS'
    AND column_name = 'ID_ENTREPOT';
  
  IF v_count = 0 THEN
    -- Add column
    EXECUTE IMMEDIATE 'ALTER TABLE utilisateurs ADD id_entrepot NUMBER';
    DBMS_OUTPUT.PUT_LINE('Column id_entrepot added successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Column id_entrepot already exists');
  END IF;
  
  -- Check if constraint exists and add if not
  SELECT COUNT(*)
  INTO v_count
  FROM user_constraints
  WHERE constraint_name = 'FK_USER_ENTREPOT';
  
  IF v_count = 0 THEN
    -- Add foreign key constraint
    EXECUTE IMMEDIATE 'ALTER TABLE utilisateurs 
      ADD CONSTRAINT fk_user_entrepot 
      FOREIGN KEY (id_entrepot) REFERENCES entrepots(id_entrepot)';
    DBMS_OUTPUT.PUT_LINE('Constraint fk_user_entrepot added successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Constraint fk_user_entrepot already exists');
  END IF;
  
  COMMIT;
END;
/

PROMPT Entrepot field check completed!

