#!/bin/bash

# ==========================================
# Script de configuration des credentials AWS
# ==========================================
# Ce script charge les credentials depuis le fichier .env

set -e

# Vérifier si le fichier .env existe
if [ ! -f .env ]; then
    echo "❌ Erreur: Le fichier .env n'existe pas"
    echo ""
    echo "Créez-le à partir de l'exemple:"
    echo "  cp .env.example .env"
    echo ""
    echo "Puis modifiez .env avec vos credentials AWS"
    exit 1
fi

# Charger les variables du fichier .env
export $(grep -v '^#' .env | xargs)

# Vérifier que les credentials sont définis
if [[ -z "$AWS_ACCESS_KEY_ID" ]] || [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "❌ Erreur: Credentials manquants dans .env"
    echo ""
    echo "Assurez-vous que .env contient:"
    echo "  AWS_ACCESS_KEY_ID=..."
    echo "  AWS_SECRET_ACCESS_KEY=..."
    exit 1
fi

echo "✓ Credentials AWS chargés depuis .env"
echo ""
echo "Variables exportées:"
echo "  - AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:20}..."
echo "  - AWS_SECRET_ACCESS_KEY: ***"
echo "  - AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION:-eu-west-2}"
echo ""
echo "Vous pouvez maintenant lancer Terraform:"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""
