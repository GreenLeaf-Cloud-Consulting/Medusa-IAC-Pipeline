#!/bin/bash
set -e

REGION="eu-west-3"
CLUSTER_NAME="prod-france-eks-rayane"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  DEPLOY ONLINE BOUTIQUE - EKS"
echo "=========================================="

# ==================== KUBECTL ====================
echo ""
echo "=== [1/4] Configuration kubectl ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# ==================== IMDS HOP LIMIT ====================
echo ""
echo "=== [2/4] Fix IMDS hop limit (tous les nœuds) ==="
for INSTANCE_ID in $(kubectl get nodes -o jsonpath='{.items[*].spec.providerID}' | tr ' ' '\n' | cut -d'/' -f5); do
  aws ec2 modify-instance-metadata-options \
    --instance-id "$INSTANCE_ID" \
    --http-put-response-hop-limit 2 \
    --http-endpoint enabled \
    --region $REGION > /dev/null
  echo "  Hop limit fixé: $INSTANCE_ID"
done

# ==================== INFRA K8S ====================
echo ""
echo "=== [3/4] Déploiement infrastructure ==="
kubectl apply -f "$SCRIPT_DIR/k8s/metrics-server.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/cluster-autoscaler.yaml"

# ==================== ONLINE BOUTIQUE ====================
echo ""
echo "=== [4/4] Déploiement Online Boutique (11 microservices) ==="
kubectl apply -f "$SCRIPT_DIR/k8s/online-boutique/namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/online-boutique/manifests.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/online-boutique/hpa.yaml"

echo ""
echo "Attente que le frontend soit prêt..."
kubectl rollout status deployment/frontend -n boutique --timeout=5m

# ==================== URL ====================
echo ""
FRONTEND_LB=""
for i in $(seq 1 30); do
  FRONTEND_LB=$(kubectl get svc frontend-external -n boutique \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$FRONTEND_LB" ]; then break; fi
  echo "  Attente ELB... ($i/30)"
  sleep 10
done

# ==================== RÉSUMÉ ====================
echo ""
echo "=========================================="
echo "  DÉPLOIEMENT TERMINÉ ✓"
echo "=========================================="
echo ""
echo "  Frontend : http://${FRONTEND_LB}"
echo ""
echo "  Test de charge :"
echo "  k6 run -e FRONTEND_URL=http://${FRONTEND_LB} k6/load-test.js"
echo ""
kubectl get pods -n boutique
