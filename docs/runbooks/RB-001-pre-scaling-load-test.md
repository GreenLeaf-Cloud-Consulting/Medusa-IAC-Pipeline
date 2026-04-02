RB-001 - Pré-scaling avant test de charge

Avant de lancer k6 il faut s'assurer que les nodes sont déjà up, sinon le Cluster Autoscaler met 3 minutes à en créer de nouveaux et pendant ce temps les requêtes échouent.

1. Vérifier l'état actuel
bash scale.sh status

2. Pré-scaler à 6 nodes
bash scale.sh up

Attendre que les 6 nodes soient en Ready, ça prend environ 3 minutes.
watch kubectl get nodes

3. Vérifier qu'aucun pod est en Pending
kubectl get pods -n boutique | grep -v Running

Si tout est OK, lancer le test :
k6 run k6/load-test.js

Après le test, repasser en mode normal pour pas laisser tourner 6 nodes pour rien :
bash scale.sh normal

Le Cluster Autoscaler va supprimer les nodes inutiles après ~10 minutes.

Seuils à surveiller sur Grafana pendant le test :
- taux d'erreur doit rester sous 5%
- p95 latence sous 5 secondes
- CPU nodes pas au dessus de 90%
