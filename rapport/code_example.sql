CREATE OR REPLACE TRIGGER trg_colis_assign_price
BEFORE INSERT OR UPDATE ON colis
FOR EACH ROW
DECLARE
  v_base NUMBER := 20;
  v_dest_entrepot NUMBER;
  v_livraison NUMBER;
BEGIN
  -- Calcul du prix
  IF :NEW.type_colis = 'FRAGILE' THEN
    v_base := 30;
  END IF;
  :NEW.prix := ROUND(:NEW.poids * v_base, 2);
  
  -- Assignation automatique à une livraison
  IF :NEW.id_entrepot_localisation IS NOT NULL 
     AND :NEW.ville_destination IS NOT NULL THEN
    -- Trouve l'entrepôt de destination
    SELECT id_entrepot INTO v_dest_entrepot
    FROM entrepots
    WHERE UPPER(ville) = UPPER(:NEW.ville_destination);
    
    -- Trouve ou crée une livraison
    -- ...
  END IF;
END;

