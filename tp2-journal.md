# Journal de bord - TP2 : Conteneurisation et Automatisation

**Nom :** Amrouche
**Projet :** todo-api

## Introduction

Pour commencer ce TP, je me suis connecté à ma VM Ubuntu via le terminal PowerShell en utilisant la commande SSH :
`ssh amrouche@<IP_DE_MA_VM>`

## Étape 1 : Préparation de l’environnement

L'objectif de cette étape est d'installer Docker sur la VM Ubuntu 22.04 et de préparer les droits d'accès.

### Commandes exécutées :

1. **Mise à jour du système :**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```
2. **Installation de Docker via le script officiel :**
   J'ai utilisé le script automatisé fourni par Docker pour installer le moteur (Docker Engine) et Docker Compose sur ma VM :
   ```bash
   curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh
   sudo sh get-docker.sh
   ```
   ![Installation de Docker](images/image_install_docker.png)

## Étape 2 : Création du Dockerfile

J'ai créé un `Dockerfile` en utilisant le principe du **Multi-stage build**.

- La première étape (`builder`) installe les outils nécessaires (`python3`, `make`, `g++`) pour compiler les dépendances comme `better-sqlite3`.
- La deuxième étape (`runtime`) crée une image finale légère en ne gardant que le strict nécessaire.

J'ai également ajouté un fichier `.dockerignore` pour éviter d'inclure des fichiers inutiles (comme `node_modules` ou les dossiers de tests) dans l'image.
