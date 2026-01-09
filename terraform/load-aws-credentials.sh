#!/bin/bash
# Script pour charger les credentials AWS depuis .env

if [ -f .env ]; then
    export $(grep -v '^#' .env | grep AWS_ | xargs)
    echo "✅ AWS credentials loaded:"
    echo "   AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:10}..."
    echo "   AWS_REGION: $AWS_REGION"
else
    echo "❌ Fichier .env non trouvé"
    exit 1
fi
