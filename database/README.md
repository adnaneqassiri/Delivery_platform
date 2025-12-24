# LogiTrack Database

Base de données Oracle pour le système de gestion logistique LogiTrack.

## 📁 Structure des Fichiers

### Fichiers Principaux (à exécuter dans l'ordre)

- `00_drop_all.sql` - Script pour supprimer toutes les tables/vues/triggers (pour réinstallation)
- `01_sequences.sql` - Toutes les séquences
- `02_tables.sql` - Toutes les tables
- `03_triggers.sql` - Tous les triggers
- `04_package.sql` - Package complet avec toutes les procédures
- `05_views.sql` - Toutes les vues
- `06_test_data.sql` - Données de test

### Scripts d'Installation

- `install.sql` - **Script d'installation principal** (exécute tous les fichiers dans l'ordre)
- `reinstall.sql` - Script pour réinstaller complètement (drop + install)

### Scripts de Configuration

- `create_user.sql` - Créer l'utilisateur Oracle (base standard)
- `create_user_pdb.sql` - Créer l'utilisateur Oracle dans PDB (Oracle XE Docker)

## 🚀 Installation Rapide

### Étape 1: Créer l'utilisateur Oracle

**Pour base standard:**
```sql
-- Connectez-vous en tant que SYSTEM ou SYS
sqlplus system/password@database @create_user.sql
```

**Pour Oracle XE Docker (PDB):**
```sql
-- Connectez-vous en tant que SYSTEM
sqlplus system/password@XEPDB1 @create_user_pdb.sql
```

### Étape 2: Installer la base de données

```sql
-- Connectez-vous en tant que logitrack
CONNECT logitrack/logitrack123@XEPDB1

-- Exécuter l'installation
@install.sql
```

**C'est tout !** Tous les fichiers sont exécutés dans le bon ordre automatiquement.

## 📝 Données de Test

Après l'installation, vous pouvez vous connecter à l'application avec:

- **Admin**: `username=admin`, `password=admin123`
- **Gestionnaire**: `username=gest1`, `password=gest123`
- **Livreur**: `username=liv1`, `password=liv123`

## 🔄 Réinstallation Complète

Pour réinstaller complètement (supprimer toutes les données et réinstaller):

```sql
CONNECT logitrack/logitrack123@XEPDB1
@reinstall.sql
```

⚠️ **Attention**: Cette opération supprime **TOUTES LES DONNÉES** de manière irréversible !

### Alternative Manuelle

```sql
-- 1. Supprimer tout
@00_drop_all.sql

-- 2. Réinstaller
@install.sql
```

## ✅ Caractéristiques

- ✅ **Installation en une seule commande** - `@install.sql`
- ✅ **Tous les correctifs intégrés** - Mutating table, statuts, KPI, etc.
- ✅ **Assignation entrepots** - Gestionnaires et livreurs assignés dans test data
- ✅ **Structure propre** - Fichiers organisés et commentés
