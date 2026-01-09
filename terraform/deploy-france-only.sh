#!/bin/bash

# Script pour déployer uniquement la région France
# Utile pour éviter de surcharger le système

set -e

echo "🇫🇷 Déploiement de l'infrastructure France uniquement"
echo ""

# Charger les credentials
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✓ Credentials chargés"
else
    echo "❌ Fichier .env introuvable"
    exit 1
fi

# Vérifier les credentials
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "❌ AWS_ACCESS_KEY_ID non défini dans .env"
    exit 1
fi

echo "✓ AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:20}..."
echo ""

# Déployer uniquement le module France
echo "📦 Déploiement de module.france_prod..."
terraform apply -target=module.france_prod -auto-approve

echo ""
echo "✅ Déploiement France terminé!"
echo ""
echo "Pour déployer Germany ensuite:"
echo "  terraform apply -target=module.germany_prod -auto-approve"
