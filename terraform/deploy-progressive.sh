#!/bin/bash

# Déploiement progressif pour éviter de crash le terminal
set -e

cd /home/jugurta-pc/code/school/Medusa-IAC-Pipeline/terraform

# Charger les credentials
export $(grep -v '^#' .env | xargs)

echo "🚀 Déploiement progressif de l'infrastructure"
echo ""

# Étape 1: VPC France
echo "📦 Étape 1/6: Création du VPC France..."
terraform apply -target=module.france_prod.module.vpc -auto-approve
echo "✅ VPC France créé"
echo ""

# Étape 2: ALB France
echo "📦 Étape 2/6: Création de l'ALB France..."
terraform apply -target=module.france_prod.module.alb -auto-approve
echo "✅ ALB France créé"
echo ""

# Étape 3: Database France
echo "📦 Étape 3/6: Création des bases de données France..."
terraform apply \
  -target=module.france_prod.module.database_primary \
  -target=module.france_prod.module.database_replica_france \
  -auto-approve
echo "✅ Databases France créées"
echo ""

# Étape 4: App instances France
echo "📦 Étape 4/6: Création des instances App France..."
terraform apply \
  -target=module.france_prod.module.app_instance_1 \
  -target=module.france_prod.module.app_instance_2 \
  -auto-approve
echo "✅ App instances France créées"
echo ""

# Pause avant Germany
echo "⏸️  Pause de 10 secondes avant de commencer Germany..."
sleep 10

# Étape 5: Infrastructure Germany (VPC + ALB + Database)
echo "📦 Étape 5/6: Création de l'infrastructure Germany..."
terraform apply -target=module.germany_prod -auto-approve
echo "✅ Infrastructure Germany créée"
echo ""

# Étape 6: Finaliser (au cas où il reste des ressources)
echo "📦 Étape 6/6: Finalisation..."
terraform apply -auto-approve
echo ""

echo "✅ Déploiement complet terminé!"
echo ""
echo "Résumé des ressources créées:"
terraform show -json | jq -r '.values.root_module.child_modules[].resources[].address' 2>/dev/null || echo "Utilisez 'terraform show' pour voir les ressources"
