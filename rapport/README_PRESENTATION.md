# Présentation LogiTrack

## 📊 Fichiers de la présentation

- `presentation.tex` : Fichier source LaTeX de la présentation Beamer
- `code_example.sql` : Exemple de code SQL utilisé dans la présentation
- `images/logo-ensa.png` : Logo de l'école (requis pour la page de titre)

## 🚀 Compilation

### Prérequis

- LaTeX installé avec les packages suivants :
  - beamer
  - babel (french)
  - listings
  - tikz
  - graphicx

### Compilation

```bash
cd rapport
pdflatex presentation.tex
pdflatex presentation.tex  # Deuxième compilation pour les références
```

Ou avec un script automatique :

```bash
pdflatex -interaction=nonstopmode presentation.tex
pdflatex -interaction=nonstopmode presentation.tex
```

## 📋 Structure de la présentation

La présentation contient **9 sections principales** :

1. **Introduction** (3 slides)
   - Contexte et objectifs
   - Vue d'ensemble du système

2. **Architecture** (2 slides)
   - Architecture 3-tiers
   - Stack technologique

3. **Base de données** (3 slides)
   - Modèle de données
   - Fonctionnalités Oracle
   - Exemple de trigger

4. **Fonctionnalités** (3 slides)
   - Rôle Administrateur
   - Rôle Gestionnaire
   - Rôle Livreur

5. **Sécurité et Performance** (2 slides)
   - Mécanismes de sécurité
   - Optimisations

6. **Démonstration** (3 slides)
   - Flux : Enregistrement d'un colis
   - Flux : Livraison
   - Flux : Récupération

7. **Résultats** (2 slides)
   - Objectifs atteints
   - Points forts

8. **Perspectives** (1 slide)
   - Évolutions possibles

9. **Conclusion** (2 slides)
   - Conclusion générale
   - Questions

**Total : ~20-25 slides**

## 🎨 Personnalisation

### Changer le thème

Modifier la ligne dans `presentation.tex` :
```latex
\usetheme{Madrid}  % Options : Madrid, Berlin, Warsaw, etc.
```

### Changer les couleurs

Modifier la ligne :
```latex
\usecolortheme{default}  % Options : default, seahorse, whale, etc.
```

### Format

La présentation est en format 16:9 (widescreen). Pour changer en 4:3 :
```latex
\documentclass[aspectratio=43]{beamer}
```

## 📝 Notes

- La présentation utilise le logo ENSA depuis `images/logo-ensa.png`
- Les exemples de code SQL sont intégrés directement dans les slides
- Le format 16:9 est optimal pour les projecteurs modernes

## 🔧 Dépannage

### Erreur "File not found: logo-ensa.png"
- Vérifier que le fichier `images/logo-ensa.png` existe
- Ou commenter la ligne `\titlegraphic{...}`

### Erreur avec TikZ
- Installer le package `texlive-pictures` ou équivalent
- Ou simplifier le diagramme d'architecture

### Erreur avec listings
- Installer le package `texlive-latex-extra` ou équivalent

