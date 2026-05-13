#!/bin/bash
# Point 23 : Sécurité du script
set -euo pipefail

# Configuration
LOG_FILE="/var/log/todo-deploy.log"
ENV_FILE=".env"
BACKUP_DIR="/var/backups/todo-api"
VERSION_DEST=${1:-} # Récupère la version passée en argument

# Fonction pour logger avec horodatage
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE
}

# Vérification de l'argument
if [ -z "$VERSION_DEST" ]; then
    log "ERREUR: Pas de version spécifiée. Usage: ./deploy.sh <version>"
    exit 1
fi

# 0. Sauvegarder l'ancienne version pour le rollback
VERSION_OLD=$(grep APP_VERSION $ENV_FILE | cut -d'=' -f2)

log "Début du déploiement de la version $VERSION_DEST (Ancienne: $VERSION_OLD)"

# 1. Pull de la nouvelle image
log "Pull de la nouvelle image : $VERSION_DEST..."
if ! docker pull ghcr.io/amr69130/todo-api:$VERSION_DEST; then
    log "ERREUR: Impossible de récupérer l'image $VERSION_DEST sur GitHub"
    exit 1
fi

# 2. Sauvegarde SQLite avant déploiement
log "Sauvegarde de la base de données..."
sudo mkdir -p $BACKUP_DIR
TIMESTAMP=$(date +%s)
# On tente la copie, mais on ne bloque pas si le fichier n'existe pas encore
docker run --rm -v todo-stack_todo-data:/data -v $BACKUP_DIR:/backup alpine cp /data/todos.db /backup/todos-$TIMESTAMP.db || true

# 3. Mise à jour du .env
log "Mise à jour du fichier .env..."
sed -i "s/APP_VERSION=.*/APP_VERSION=$VERSION_DEST/" $ENV_FILE

# 4. Recréer uniquement le service app
log "Relance du service app..."
docker compose up -d --no-deps app

# 5. Smoke test (Point 22.5)
log "Vérification du service (Smoke Test)..."
SUCCESS=false
for i in {1..5}; do
    if curl -f http://localhost/health; then
        log "Smoke test réussi !"
        SUCCESS=true
        break
    fi
    log "Tentative $i/5 échouée, attente..."
    sleep 5
done

# 6. Rollback automatique (Point 22.6)
if [ "$SUCCESS" = false ]; then
    log "ÉCHEC du smoke test. Lancement du rollback..."

    # Restaurer l'ancienne version dans .env
    sed -i "s/APP_VERSION=.*/APP_VERSION=$VERSION_OLD/" $ENV_FILE

    # Restaurer la base de données
    docker run --rm -v todo-stack_todo-data:/data -v $BACKUP_DIR:/backup alpine cp /backup/todos-$TIMESTAMP.db /data/todos.db

    # Relancer l'ancienne version
    docker compose up -d --no-deps app
    log "Rollback terminé. Version $VERSION_OLD restaurée."
    exit 1
fi

log "Déploiement de la version $VERSION_DEST terminé avec succès."