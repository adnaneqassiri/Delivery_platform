--------------------------------------------------
-- ADD ENTREPOT FIELD TO UTILISATEURS FOR LIVREURS
-- Livreurs are bound to an entrepot and can only see/take
-- deliveries from their entrepot
--------------------------------------------------

-- Add id_entrepot column to utilisateurs table
ALTER TABLE utilisateurs ADD id_entrepot NUMBER;

-- Add foreign key constraint
ALTER TABLE utilisateurs 
ADD CONSTRAINT fk_user_entrepot 
FOREIGN KEY (id_entrepot) REFERENCES entrepots(id_entrepot);

-- Add comment
COMMENT ON COLUMN utilisateurs.id_entrepot IS 'Entrepot assigned to livreur (for LIVREUR role only)';

COMMIT;

PROMPT Entrepot field added to utilisateurs table!


