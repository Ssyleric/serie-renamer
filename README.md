# 📌 Script de renommage et d'organisation des séries TV

## 📖 Description
Ce script automatise le renommage et l'organisation des dossiers de séries TV en se basant sur la base de données **TMDb (The Movie Database)**. Il corrige les noms des dossiers, ajoute 
l'année de première diffusion et fusionne les doublons tout en conservant l'intégrité des fichiers.

## 🔍 Fonctionnalités
✅ Recherche automatique du titre officiel et de l'année de diffusion via TMDb.  
✅ Renommage des dossiers selon le format **"Nom de la série (Année)"**.  
✅ Suppression des préfixes comme **"Marvel's"** si TMDb utilise un nom différent.  
✅ Fusion des dossiers de doublons pour éviter les répétitions.  
✅ Génération d'un **rapport final** indiquant les dossiers renommés, fusionnés et ceux à vérifier manuellement.  

## ⚙️ Prérequis
- **Un NAS Synology ou un serveur Linux**
- **Entware installé** (si utilisé sur un NAS Synology)
- **jq installé** (pour traiter les réponses JSON de l'API TMDb)
- **cURL installé** (pour interroger l'API TMDb)

### 📦 Installation des dépendances
Sur un système Debian/Ubuntu :
```sh
sudo apt update && sudo apt install jq curl
```
Sur un NAS Synology avec Entware :
```sh
opkg update && opkg install jq curl
```

## 📂 Structure du répertoire
Le script cible un répertoire contenant des séries :
```
/volume2/serie/
    ├── Loki (2021)/
    ├── Breaking Bad (2008)/
    ├── Stranger Things (2016)/
    ├── Série à vérifier/
```

## 🚀 Utilisation
### 1️⃣ Modifier la configuration
Dans le script, adapter la variable `base_dir` :
```bash
base_dir="/volume2/serie"
```
### 2️⃣ Lancer le script
```sh
bash rename_series.sh
```

## 📊 Rapport final
À la fin du script, un résumé des opérations effectuées est affiché :
```
📂 Total des dossiers traités  : 50
✍️  Dossiers renommés          : 12
🔄 Dossiers fusionnés         : 5
⚠️  Dossiers à vérifier manuellement : 3

🚨 LISTE DES DOSSIERS À VÉRIFIER :
   - Inconnu Série 1
   - Another Show (Incorrect)
   - Test Series (2019)
✅ Renommage terminé !
```

## 🔧 Personnalisation
- Modifier la **clé API TMDb** si nécessaire :
```bash
api_key="VOTRE_CLE_API"
```
- Ajouter d'autres exceptions de renommage dans la fonction `normalize_series_name()`.

## ❌ Limitations
- Si une série n'est pas trouvée sur TMDb, elle est ajoutée à la liste des dossiers à vérifier.
- Les fichiers vidéo **(.mkv, .avi)** et les métadonnées **(.jpg, .nfo)** sont conservés.
- **Le script ne supprime aucun fichier**, sauf en cas de fusion de dossiers.

## ✨ Améliorations possibles
- Ajout d'un mode **dry-run** pour simuler les modifications avant exécution.
- Création d'un fichier **log** détaillé des actions effectuées.

---
✍️ **Auteur :** Script personnalisé pour NAS Synology & Linux.  
📅 **Dernière mise à jour :** Février 2025


