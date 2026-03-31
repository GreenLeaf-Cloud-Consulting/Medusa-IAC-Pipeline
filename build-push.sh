#!/bin/bash
set -e

REGION="eu-west-3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Récupération des URLs ECR depuis Terraform ==="
cd "$SCRIPT_DIR/terraform"
BACKEND_ECR=$(terraform output -raw france_ecr_backend_url)
STOREFRONT_ECR=$(terraform output -raw france_ecr_storefront_url)
ACCOUNT_ID=$(echo "$BACKEND_ECR" | cut -d'.' -f1)

echo "Backend ECR   : $BACKEND_ECR"
echo "Storefront ECR: $STOREFRONT_ECR"

echo ""
echo "=== Login ECR ==="
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# ==================== BACKEND ====================
echo ""
echo "=== [1/2] Build et push Backend ==="
cd "$SCRIPT_DIR/docker/backend"
docker build -t medusa-backend:latest .
docker tag medusa-backend:latest "${BACKEND_ECR}:latest"
docker push "${BACKEND_ECR}:latest"

echo ""
echo "=== Déploiement Backend sur EKS ==="
kubectl rollout restart deployment/medusa-backend -n medusa

echo "Attente que le backend soit prêt..."
kubectl rollout status deployment/medusa-backend -n medusa --timeout=5m

# Récupérer l'URL du backend (LoadBalancer)
BACKEND_LB=$(kubectl get svc medusa-backend -n medusa \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$BACKEND_LB" ]; then
  echo ""
  echo "⚠️  Le LoadBalancer backend n'a pas encore d'URL."
  echo "    Lance: kubectl get svc -n medusa"
  echo "    Et note l'EXTERNAL-IP du service medusa-backend."
  echo ""
  read -p "Entrez l'URL du backend (ex: xxx.eu-west-3.elb.amazonaws.com) : " BACKEND_LB
fi

BACKEND_URL="http://${BACKEND_LB}"
echo "Backend URL: $BACKEND_URL"

# ==================== STOREFRONT ====================
echo ""
echo "=== [2/2] Build Storefront ==="
echo ""
echo "Le storefront a besoin d'une Publishable API Key Medusa."
echo "  1. Ouvre: ${BACKEND_URL}/app  (admin Medusa)"
echo "  2. Va dans Settings > Publishable API Keys"
echo "  3. Crée une nouvelle clé pour 'Storefront'"
echo ""
read -p "Entre la Publishable API Key (pk_...): " PUBLISHABLE_KEY

if [ -z "$PUBLISHABLE_KEY" ]; then
  echo "❌ Clé vide. Storefront non buildé."
  exit 1
fi

cd "$SCRIPT_DIR/docker/storefront"
docker build \
  --build-arg NEXT_PUBLIC_MEDUSA_BACKEND_URL="${BACKEND_URL}" \
  --build-arg MEDUSA_BACKEND_URL="http://medusa-backend" \
  --build-arg NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY="${PUBLISHABLE_KEY}" \
  -t medusa-storefront:latest .
docker tag medusa-storefront:latest "${STOREFRONT_ECR}:latest"
docker push "${STOREFRONT_ECR}:latest"

echo ""
echo "=== Déploiement Storefront sur EKS ==="
kubectl rollout restart deployment/medusa-storefront -n medusa

kubectl rollout status deployment/medusa-storefront -n medusa --timeout=5m

echo ""
echo "=== Déploiement terminé ==="
kubectl get svc -n medusa
