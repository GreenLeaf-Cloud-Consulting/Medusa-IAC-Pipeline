#!/bin/bash
# ==========================================
# GESTION DU SCALING EKS - Online Boutique
# ==========================================
# Usage:
#   bash scale.sh up        → pré-scale pour test de charge (6 nodes)
#   bash scale.sh down      → scale down pour économiser (0 nodes)
#   bash scale.sh normal    → mode normal (2 nodes)
#   bash scale.sh status    → état actuel du cluster
# ==========================================

set -e

CLUSTER="prod-france-eks-rayane"
NODEGROUP="prod-france-eks-ng-rayane"
REGION="eu-west-3"

cd "$(dirname "$0")/terraform" && source load-aws-credentials.sh && cd ..

scale() {
  aws eks update-nodegroup-config \
    --cluster-name $CLUSTER \
    --nodegroup-name $NODEGROUP \
    --scaling-config minSize=$1,maxSize=10,desiredSize=$2 \
    --region $REGION > /dev/null
  echo "✅ Scaling demandé : $2 nodes (min $1, max 10)"
  echo "⏳ Attendre ~3 minutes pour que les nodes soient Ready"
}

case "$1" in
  up)
    echo "🚀 Pré-scale Black Friday → 8 nodes (max 10)"
    scale 8 8
    echo ""
    echo "Surveiller avec : watch kubectl get nodes"
    ;;
  down)
    echo "💤 Scale down → 0 nodes (économies)"
    kubectl scale deployment --all --replicas=0 -n boutique 2>/dev/null || true
    kubectl scale deployment --all --replicas=0 -n monitoring 2>/dev/null || true
    scale 0 0
    ;;
  normal)
    echo "⚙️  Mode normal → 2 nodes"
    scale 1 2
    ;;
  status)
    echo "📊 État du cluster :"
    echo ""
    kubectl get nodes
    echo ""
    kubectl top nodes 2>/dev/null || echo "(metrics-server pas encore prêt)"
    echo ""
    echo "Pods Online Boutique :"
    kubectl get pods -n boutique --no-headers | wc -l | xargs echo "  Total pods:"
    kubectl get pods -n boutique --no-headers | grep -c Running | xargs echo "  Running:"
    ;;
  *)
    echo "Usage: bash scale.sh [up|down|normal|status]"
    echo ""
    echo "  up      → 6 nodes  (avant test de charge)"
    echo "  normal  → 2 nodes  (usage quotidien)"
    echo "  down    → 0 nodes  (fin de journée)"
    echo "  status  → état actuel"
    exit 1
    ;;
esac
