# Database Fixes

## Fix 1: Mutating Table Error (07_fix_trigger_mutating.sql)
**Problem**: When marking a livraison as delivered, trigger `trg_livraison_arrivee` tries to read from `colis` table while updating `livraisons`, causing ORA-04091 error.

**Solution**: Converted to compound trigger that collects colis IDs before the update, then uses them in AFTER EACH ROW.

**To apply**: Run `@database/07_fix_trigger_mutating.sql` as logitrack user.

## Fix 2: Livreur Entrepot Binding (08_add_livreur_entrepot.sql)
**Problem**: Livreurs need to be bound to an entrepot and can only see/take deliveries from their entrepot.

**Solution**: Added `id_entrepot` column to `utilisateurs` table.

**To apply**: Run `@database/08_add_livreur_entrepot.sql` as SYSTEM or logitrack user.

## Fix 3: Clients Count (09_fix_clients_count.sql)
**Problem**: Clients count in KPI dashboard not calculated correctly.

**Solution**: Recreated the view to ensure correct count.

**To apply**: Run `@database/09_fix_clients_count.sql` as logitrack user.

## Installation Order
1. Run `08_add_livreur_entrepot.sql` (adds column)
2. Run `07_fix_trigger_mutating.sql` (fixes trigger)
3. Run `09_fix_clients_count.sql` (fixes view)

Or run all at once:
```sql
@database/08_add_livreur_entrepot.sql
@database/07_fix_trigger_mutating.sql
@database/09_fix_clients_count.sql
```


