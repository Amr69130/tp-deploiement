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

### Résultat du build :

L'image a été construite avec succès. Grâce à l'utilisation d'une image de base `alpine` et au nettoyage des dépendances de développement (`npm prune`), l'image finale est optimisée.

![Capture d'écran du build et de la taille de l'image](images/image2_build_success.png)

## Étape 3 : Publication sur GitHub Packages (GHCR)

Une fois l'image construite localement, je l'ai publiée sur le registre de conteneurs de GitHub.
Pour ce faire, j'ai généré un PAT (Personal Access Token) avec les portées (scopes) write:packages afin d'autoriser ma VM à s'authentifier sur le registre GHCR (GitHub Container Registry).

### Actions :

1. Connexion au registre avec un Personal Access Token (PAT) :
   `docker login ghcr.io -u Amr69130`
2. Tag de l'image pour l'associer à mon dépôt GitHub.
3. Push de l'image vers GHCR.
   ![Capture d'écran du push vers GHCR](images/image3_docker_push.png)

L'image est désormais stockée sur GitHub Packages, prête à être déployée sur n'importe quel serveur.

### Preuve du bon fonctionnement :

Le conteneur est désormais actif et l'API répond correctement.

![Capture d'écran du conteneur opérationnel](images/image4_docker_ps_healthy.png)

### Preuve de présence dans les packages de Github :

![Capture d'écran de github](images/image5_packages_github.png)

Étape 4 : Docker Compose et orchestration

1. Préparation de l'environnement
   J'ai créé le dossier /opt/todo-stack/ pour centraliser les fichiers de configuration de la stack. J'ai modifié les droits du dossier pour permettre mon utilisateur d'y travailler sans restrictions.

sudo mkdir -p /opt/todo-stack
sudo chown $USER:$USER /opt/todo-stack
cd /opt/todo-stack

### 2. Configuration du Reverse Proxy et des variables d'environnement

J'ai configuré Nginx pour qu'il agisse comme porte d'entrée sur le port 80 et redirige le trafic vers mon application. J'ai également créé un fichier `.env` pour stocker mes informations sensibles (nom d'utilisateur, version de l'image, secret JWT) de manière sécurisée.

**Fichier `nginx.conf` :**

```nginx
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://app:3000;
        }
    }
}

```

### Vérification des fichiers de configuration :

Avant de lancer la stack, j'ai vérifié la présence des fichiers et les permissions de sécurité du fichier `.env`.

![Vérification des fichiers et permissions](images/image6_verif_fichiers_stack.png)

J'ai vérifié le contenu de mes fichiers de configuration pour m'assurer que les variables et les paramètres du proxy Nginx étaient corrects.
![Vérification des fichiers et permissions](images/image7_contenu_config.png)

### Orchestration avec Docker Compose

Le but est de mettre en place une stack complète (API + Reverse Proxy) automatisée.

1. Configuration et fichiers
   J'ai créé les trois fichiers nécessaires dans /opt/todo-stack :

.env : Pour les secrets (JWT, version, utilisateur).

nginx.conf : Pour configurer Nginx en mode Reverse Proxy.

docker-compose.yml : Pour définir les services, les réseaux et les volumes.

2. Débogage du Healthcheck
   Lors du premier lancement via docker compose up -d, le conteneur de l'application restait en état unhealthy, empêchant Nginx de démarrer.

Analyse : La commande docker compose logs app montrait que l'API était bien lancée (API listening on 3000), mais le test de santé (basé sur curl) échouait car l'utilitaire n'était pas présent dans l'image.

Correction : J'ai modifié le docker-compose.yml pour utiliser une commande nc (netcat) plus légère pour vérifier l'ouverture du port.

3. Lancement réussi
   Après correction, la stack a démarré correctement.

Vérification de l'état des services :
amrouche@amrouche:/opt/todo-stack$ docker compose ps
NAME IMAGE STATUS PORTS
todo-stack-app-1 ghcr.io/amr69130/todo-api... Up (healthy) 3000/tcp
todo-stack-nginx-1 nginx:alpine Up 0.0.0.0:80->80/tcp
![Vérification du demarrage stack](images/image8_stack_up.png)
