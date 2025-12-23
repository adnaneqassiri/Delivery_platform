# LogiTrack Database

Base de données Oracle pour le système de gestion logistique LogiTrack.

## 📁 Structure

- `00_drop_all.sql` - Script pour supprimer toutes les tables/vues/triggers (pour réinstallation)
- `01_sequences.sql` - Toutes les séquences
- `02_tables.sql` - Toutes les tables (avec `id_entrepot` dans `utilisateurs`)
- `03_triggers.sql` - Tous les triggers (avec fixes mutating table intégrés)
- `04_package.sql` - Package complet avec toutes les procédures
- `05_views.sql` - Toutes les vues (avec fixes KPI)
- `06_test_data.sql` - Données de test (avec assignation entrepots)
- `install.sql` - Script d'installation principal
- `create_user.sql` - Script pour créer l'utilisateur Oracle

## 🚀 Installation Rapide

### 1. Créer l'utilisateur Oracle (si nécessaire)

Connectez-vous en tant que `SYSTEM` ou `SYS`:

```sql
@create_user.sql
```

### 2. Se connecter en tant que `logitrack`

```sql
CONNECT logitrack/logitrack123@XEPDB1
```

### 3. Exécuter le script d'installation

```sql
@install.sql
```

**C'est tout !** Tous les fichiers sont exécutés dans le bon ordre automatiquement.

## ✅ Caractéristiques

- ✅ **Version consolidée** - Tous les correctifs intégrés
- ✅ **Installation en une seule commande** - `@install.sql`
- ✅ **Fixes intégrés** - Mutating table, statuts, KPI, etc.
- ✅ **Assignation entrepots** - Gestionnaires et livreurs assignés dans test data

## 🔧 Corrections intégrées

1. **Colonne `id_entrepot` dans `utilisateurs`** - Ajoutée automatiquement
2. **Fix mutating table** - Triggers utilisent `PRAGMA AUTONOMOUS_TRANSACTION`
3. **Statuts colis corrigés** - `ENREGISTRE`, `LIVRE`, `RECUPEREE`, etc.
4. **Auto-création livraisons** - Nouvelle livraison créée automatiquement après livraison
5. **KPI corrigés** - Chiffre d'affaires et compteurs corrects
6. **Assignation entrepots** - Gestionnaires et livreurs assignés dans test data

## 📝 Données de test

Après l'installation, vous pouvez vous connecter avec:

- **Admin**: `username=admin`, `password=admin123`
- **Gestionnaire**: `username=gest1`, `password=gest123`
- **Livreur**: `username=liv1`, `password=liv123`

## 🔄 Pour réinstaller complètement

Si vous voulez tout réinstaller à zéro (supprimer toutes les données et réinstaller):

### Option 1: Script Automatique (Recommandé)

```sql
CONNECT logitrack/logitrack123@XEPDB1
@reinstall.sql
```

### Option 2: Étapes Manuelles

```sql
-- 1. Supprimer tout
@00_drop_all.sql

-- 2. Réinstaller
@install.sql
```

⚠️ **Attention**: Cette opération supprime **TOUTES LES DONNÉES** de manière irréversible !

## 📚 Fichiers utilitaires

- `create_user.sql` - Créer l'utilisateur Oracle
- `fix_user.sql` - Réparer l'utilisateur si nécessaire
- `verify_user.sql` - Vérifier l'utilisateur
- `test_connection.sql` - Tester la connexion
