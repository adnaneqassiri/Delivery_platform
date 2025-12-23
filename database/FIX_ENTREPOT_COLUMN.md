# Fix: Ajouter la colonne id_entrepot à la table utilisateurs

## Problème
L'erreur `ORA-00904: "ID_ENTREPOT": invalid identifier` indique que la colonne `id_entrepot` n'existe pas dans la table `utilisateurs`.

## Solution

Exécutez le script SQL suivant pour ajouter la colonne :

### Option 1: Script sécurisé (recommandé)
```bash
sqlplus logitrack/logitrack123@localhost:1521/XEPDB1 @database/13_add_entrepot_to_utilisateurs.sql
```

### Option 2: Script original
```bash
sqlplus logitrack/logitrack123@localhost:1521/XEPDB1 @database/08_add_livreur_entrepot.sql
```

### Option 3: Via SQL*Plus directement
```sql
-- Connectez-vous à la base de données
sqlplus logitrack/logitrack123@localhost:1521/XEPDB1

-- Exécutez les commandes suivantes
ALTER TABLE utilisateurs ADD id_entrepot NUMBER;

ALTER TABLE utilisateurs 
ADD CONSTRAINT fk_user_entrepot 
FOREIGN KEY (id_entrepot) REFERENCES entrepots(id_entrepot);

COMMIT;
```

## Vérification

Après avoir exécuté le script, vérifiez que la colonne existe :

```sql
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'UTILISATEURS' 
  AND column_name = 'ID_ENTREPOT';
```

Vous devriez voir une ligne avec `ID_ENTREPOT` et `NUMBER`.

## Assignation d'un entrepôt à un utilisateur

Pour assigner un entrepôt à un gestionnaire (via l'interface admin) :

1. Allez dans "Users Management"
2. Modifiez l'utilisateur gestionnaire
3. Sélectionnez un entrepôt dans le champ "Entrepot"

Ou directement en SQL :

```sql
UPDATE utilisateurs 
SET id_entrepot = 1  -- Remplacez 1 par l'ID de l'entrepôt
WHERE id_utilisateur = 2;  -- Remplacez 2 par l'ID de l'utilisateur

COMMIT;
```

## Après la correction

1. Redémarrez le serveur backend
2. Reconnectez-vous en tant que gestionnaire
3. L'erreur devrait disparaître et vous pourrez créer des colis


