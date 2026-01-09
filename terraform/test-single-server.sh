#!/bin/bash
# Script de test rapide sur UN SEUL serveur France app-1

set -e

SERVER="35.179.104.103"
KEY="keys/jugurta-dev-eu-west-2-app-1-key.pem"
SERVER_NAME="France App-1"

echo "=========================================="
echo "🧪 TEST RAPIDE SUR $SERVER_NAME"
echo "=========================================="

# Copier les fichiers corrigés
echo "📦 1. Copie des fichiers corrigés..."
scp -i "$KEY" ansible/roles/medusa/templates/Dockerfile.j2 admin@$SERVER:~/medusa/Dockerfile
scp -i "$KEY" ansible/roles/medusa/templates/docker-compose-redis.yml.j2 admin@$SERVER:~/medusa/docker-compose.yml

echo ""
echo "🔧 2. Fix docker-compose.yml (remplacer variables Jinja)..."
ssh -i "$KEY" admin@$SERVER << 'ENDSSH'
cd ~/medusa

# Remplacer les variables Jinja par des valeurs réelles
sed -i 's/{{ medusa_app_dir }}/\/home\/admin\/medusa/g' docker-compose.yml
sed -i 's/{{ medusa_backend_port }}/9000/g' docker-compose.yml

echo "✅ docker-compose.yml prêt"
cat docker-compose.yml
ENDSSH

echo ""
echo "🐳 3. Arrêt des anciens containers..."
ssh -i "$KEY" admin@$SERVER 'cd ~/medusa && sg docker -c "docker-compose down"'

echo ""
echo "🗑️  4. Suppression ancienne image pour forcer rebuild..."
ssh -i "$KEY" admin@$SERVER 'sg docker -c "docker rmi -f medusa-backend:latest || true"'

echo ""
echo "🔨 5. BUILD (ça va prendre 15-20 min la première fois)..."
echo "⏳ Patience..."
ssh -i "$KEY" admin@$SERVER 'cd ~/medusa && sg docker -c "docker-compose build medusa 2>&1 | tail -30"'

if [ $? -eq 0 ]; then
    echo "✅ Build réussi!"
else
    echo "❌ Build échoué!"
    exit 1
fi

echo ""
echo "🚀 6. Démarrage des containers..."
ssh -i "$KEY" admin@$SERVER 'cd ~/medusa && sg docker -c "docker-compose up -d"'

echo ""
echo "⏳ 7. Attente 45 secondes pour migrations + démarrage..."
sleep 45

echo ""
echo "📊 8. Vérification de l'état..."
ssh -i "$KEY" admin@$SERVER << 'ENDSSH'
echo "=== Containers ==="
docker ps

echo ""
echo "=== Derniers logs (60 lignes) ==="
docker logs --tail 60 medusa-backend

echo ""
echo "=== Santé du backend ==="
docker inspect medusa-backend | grep -A 5 '"Health"' || echo "Pas de healthcheck"

echo ""
echo "=== Test connexion DB ==="
timeout 3 bash -c "echo > /dev/tcp/10.0.1.217/5432" 2>&1 && echo "✅ PostgreSQL accessible" || echo "❌ PostgreSQL NOT accessible"
ENDSSH

echo ""
echo "=========================================="
echo "✅ TEST TERMINÉ!"
echo "=========================================="
echo ""
echo "💡 Prochaines étapes:"
echo "   - Si ça marche → Lance terraform apply pour déployer partout"
echo "   - Si ça échoue → Analyse les logs ci-dessus"
