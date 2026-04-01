#!/bin/bash
set -e

REGION="eu-west-3"
CLUSTER_NAME="prod-france-eks-rayane"
ADMIN_EMAIL="admin@test.com"
ADMIN_PASSWORD="Admin1234!"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  DEPLOY MEDUSA - EKS"
echo "=========================================="

# ==================== KUBECTL ====================
echo ""
echo "=== [1/7] Configuration kubectl ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# ==================== IMDS HOP LIMIT ====================
echo ""
echo "=== [2/7] Fix IMDS hop limit (tous les nœuds) ==="
for INSTANCE_ID in $(kubectl get nodes -o jsonpath='{.items[*].spec.providerID}' | tr ' ' '\n' | cut -d'/' -f5); do
  echo "  Instance: $INSTANCE_ID"
  aws ec2 modify-instance-metadata-options \
    --instance-id "$INSTANCE_ID" \
    --http-put-response-hop-limit 2 \
    --http-endpoint enabled \
    --region $REGION > /dev/null
done
echo "Hop limit mis à 2 sur tous les nœuds ✓"

# ==================== K8S BASE ====================
echo ""
echo "=== [3/7] Déploiement Kubernetes (base) ==="
kubectl apply -f "$SCRIPT_DIR/k8s/namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/secret.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/postgres/"
kubectl apply -f "$SCRIPT_DIR/k8s/pgbouncer/"
kubectl apply -f "$SCRIPT_DIR/k8s/metrics-server.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/cluster-autoscaler.yaml"

echo "Attente que Postgres soit prêt..."
kubectl rollout status deployment/postgres -n medusa --timeout=3m

echo "Attente que PgBouncer soit prêt..."
kubectl rollout status deployment/pgbouncer -n medusa --timeout=2m

# ==================== BACKEND SERVICE (ELB URL) ====================
echo ""
echo "=== [4/7] Récupération de l'ELB backend ==="
kubectl apply -f "$SCRIPT_DIR/k8s/backend/service.yaml" 2>/dev/null || true

echo "Attente de l'ELB backend..."
BACKEND_LB=""
for i in $(seq 1 24); do
  BACKEND_LB=$(kubectl get svc medusa-backend -n medusa \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$BACKEND_LB" ]; then break; fi
  echo "  En attente... ($i/24)"
  sleep 5
done

if [ -z "$BACKEND_LB" ]; then
  echo "Timeout ELB"
  kubectl get svc -n medusa
  read -p "Entrez l'hostname du LoadBalancer backend: " BACKEND_LB
fi

BACKEND_URL="http://${BACKEND_LB}"
echo "Backend ELB: $BACKEND_URL ✓"

# ==================== CONFIGMAP ====================
echo ""
echo "=== [5/7] Mise à jour ConfigMap ==="
kubectl create configmap medusa-config \
  --namespace medusa \
  --from-literal=DATABASE_HOST=postgres \
  --from-literal=DATABASE_PORT=5432 \
  --from-literal=DATABASE_NAME=medusa \
  --from-literal=DATABASE_USER=medusa \
  --from-literal=MEDUSA_BACKEND_URL="$BACKEND_URL" \
  --from-literal=ADMIN_CORS="$BACKEND_URL" \
  --from-literal=STORE_CORS="$BACKEND_URL" \
  --from-literal=AUTH_CORS="$BACKEND_URL" \
  --from-literal=S3_BUCKET=jugurta-prod-medusa-assets-global \
  --from-literal=S3_REGION=eu-west-1 \
  --from-literal=NODE_ENV=production \
  --from-literal=PORT=9000 \
  --dry-run=client -o yaml | kubectl apply -f -

# ==================== DEPLOY BACKEND ====================
echo ""
echo "=== [6/7] Déploiement backend ==="
kubectl apply -f "$SCRIPT_DIR/k8s/backend/"
kubectl apply -f "$SCRIPT_DIR/k8s/backend/hpa.yaml"
echo "Attente backend..."
kubectl rollout status deployment/medusa-backend -n medusa --timeout=5m

# Attente que le backend soit réellement prêt (health check)
echo "Attente que le backend réponde..."
for i in $(seq 1 30); do
  STATUS=$(curl -sf "$BACKEND_URL/health" 2>/dev/null || echo "")
  if [ "$STATUS" = "OK" ]; then break; fi
  echo "  Backend pas encore prêt... ($i/30)"
  sleep 5
done

# ==================== ADMIN USER + PUBLISHABLE KEY ====================
echo ""
echo "=== Création admin user ==="
kubectl exec -n medusa deployment/medusa-backend -- \
  npx medusa user -e "$ADMIN_EMAIL" -p "$ADMIN_PASSWORD" 2>/dev/null || echo "User existe déjà ✓"

echo "=== Récupération de la Publishable Key ==="
TOKEN=$(curl -sf -X POST "$BACKEND_URL/auth/user/emailpass" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | jq -r '.token')

PUBLISHABLE_KEY=$(curl -sf -X POST "$BACKEND_URL/admin/api-keys" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Storefront","type":"publishable"}' | jq -r '.api_key.token')

echo "Publishable Key: $PUBLISHABLE_KEY ✓"

# ==================== BUILD & PUSH ====================
echo ""
echo "=== [7/7] Build et push des images Docker ==="
cd "$SCRIPT_DIR/terraform"
BACKEND_ECR=$(terraform output -raw france_ecr_backend_url)
STOREFRONT_ECR=$(terraform output -raw france_ecr_storefront_url)
ACCOUNT_ID=$(echo "$BACKEND_ECR" | cut -d'.' -f1)

aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Build backend..."
cd "$SCRIPT_DIR/docker/backend"
docker build -t medusa-backend:latest .
docker tag medusa-backend:latest "${BACKEND_ECR}:latest"
docker push "${BACKEND_ECR}:latest"

echo "Build storefront..."
cd "$SCRIPT_DIR/docker/storefront"
docker build \
  --build-arg NEXT_PUBLIC_MEDUSA_BACKEND_URL="$BACKEND_URL" \
  --build-arg MEDUSA_BACKEND_URL="http://medusa-backend" \
  --build-arg NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
  -t medusa-storefront:latest .
docker tag medusa-storefront:latest "${STOREFRONT_ECR}:latest"
docker push "${STOREFRONT_ECR}:latest"

# ==================== DEPLOY COMPLET ====================
echo ""
echo "=== Déploiement complet Kubernetes ==="
kubectl apply -f "$SCRIPT_DIR/k8s/storefront/"
kubectl apply -f "$SCRIPT_DIR/k8s/storefront/hpa.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/seed-job.yaml"

kubectl rollout restart deployment/medusa-backend -n medusa
kubectl rollout restart deployment/medusa-storefront -n medusa

echo "Attente backend..."
kubectl rollout status deployment/medusa-backend -n medusa --timeout=5m
echo "Attente storefront..."
kubectl rollout status deployment/medusa-storefront -n medusa --timeout=5m

# ==================== RÉSUMÉ ====================
echo ""
echo "=========================================="
echo "  DÉPLOIEMENT TERMINÉ ✓"
echo "=========================================="
kubectl get svc -n medusa
echo ""
STOREFRONT_LB=$(kubectl get svc medusa-storefront -n medusa \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
echo "Backend:    $BACKEND_URL"
echo "Storefront: http://${STOREFRONT_LB}"
echo "Admin:      $BACKEND_URL/app"
echo ""
