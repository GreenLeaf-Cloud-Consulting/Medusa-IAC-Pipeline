#!/bin/bash
set -e

echo "========================================="
echo "🚀 Déploiement Medusa Multi-Région"
echo "========================================="
echo ""

# Charger les variables d'environnement
if [ -f .env ]; then
    echo "✓ Chargement des variables d'environnement..."
    set -a
    source .env
    set +a
else
    echo "❌ Fichier .env introuvable !"
    exit 1
fi

# Régénérer l'inventaire Ansible depuis Terraform
echo ""
echo "🔄 Régénération de l'inventaire Ansible..."
cd ../
terraform apply -refresh-only -auto-approve > /dev/null 2>&1
cd ansible/

# Vérifier la connectivité
echo ""
echo "📡 Vérification de la connectivité..."
if ansible all -i inventory/hosts.yml -m ping --one-line 2>/dev/null | grep -q SUCCESS; then
    echo "✓ Instances accessibles"
else
    echo "⚠️  Certaines instances ne répondent pas"
    echo "   Voulez-vous continuer quand même ? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Déploiement par phases
echo ""
echo "========================================="
echo "Phase 1: Configuration de la base de données"
echo "========================================="
ansible-playbook -i inventory/hosts.yml site.yml \
    --limit 'database_primary' \
    --tags 'system,postgresql'

echo ""
echo "========================================="
echo "Phase 2: Configuration des applications"
echo "========================================="
ansible-playbook -i inventory/hosts.yml site.yml \
    --limit 'medusa_app' \
    --tags 'system,docker,nodejs,medusa'

echo ""
echo "========================================="
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "========================================="
echo ""
echo "📍 URLs de test:"

# Récupérer les vraies URLs depuis Terraform
cd ../
FRANCE_URL=$(terraform output -raw france_alb_url 2>/dev/null || echo "N/A")
GERMANY_URL=$(terraform output -raw germany_alb_url 2>/dev/null || echo "N/A")
cd ansible/

echo "   France:  $FRANCE_URL"
echo "   Germany: $GERMANY_URL"
echo ""
