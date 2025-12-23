# Réinstallation Complète de la Base de Données

## 🗑️ Supprimer et Réinstaller Tout

Pour supprimer complètement la base de données existante et réinstaller à partir de zéro:

### Option 1: Script Automatique (Recommandé)

```sql
CONNECT logitrack/logitrack123@XEPDB1
@reinstall.sql
```

Ce script fait tout automatiquement:
1. Supprime tous les objets existants
2. Réinstalle tout proprement

### Option 2: Étapes Manuelles

Si vous préférez faire étape par étape:

```sql
-- 1. Se connecter
CONNECT logitrack/logitrack123@XEPDB1

-- 2. Supprimer tout
@00_drop_all.sql

-- 3. Réinstaller
@install.sql
```

## 📋 Ce qui sera supprimé

- ✅ Toutes les tables (utilisateurs, entrepots, colis, livraisons, etc.)
- ✅ Tous les triggers
- ✅ Tous les packages et procédures
- ✅ Toutes les vues
- ✅ Toutes les séquences
- ✅ **TOUTES LES DONNÉES** (utilisateurs, colis, livraisons, etc.)

## ⚠️ Attention

**Cette opération est irréversible !** Toutes les données seront perdues.

## ✅ Après la réinstallation

Vous aurez une base de données fraîche avec les données de test:

- **Admin**: `admin` / `admin123`
- **Gestionnaire**: `gest1` / `gest123`
- **Livreur**: `liv1` / `liv123`
