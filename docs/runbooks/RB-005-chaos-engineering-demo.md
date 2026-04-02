RB-005 - Chaos Engineering pendant la démo

Avant de lancer quoi que ce soit vérifier que tous les pods sont Running :
kubectl get pods -n boutique | grep -v Running

Si y'a des pods en erreur, les fixer avant de commencer le chaos.

Lancer toutes les expériences :
kubectl apply -f k8s/chaos/experiments.yaml

Ce qui va se passer :
- Un pod cartservice va se faire tuer et redémarrer en boucle
- Un pod recommendationservice pareil
- Le productcatalogservice va avoir 200ms de latence en plus
- Le frontend va être stressé CPU à 80%

Sur Grafana on devrait voir les restarts monter et le taux d'erreur potentiellement augmenter un peu. Le site doit rester accessible malgré tout.

Pour tester pendant le chaos : aller sur le site, ajouter un produit au panier, passer une commande. Si ça marche c'est bon.

Stopper le chaos :
kubectl delete -f k8s/chaos/experiments.yaml

Les pods vont se stabiliser en moins de 30 secondes.

Si le chaos provoque trop d'impact et que le site est vraiment down :
kubectl delete -f k8s/chaos/experiments.yaml
kubectl rollout restart deployment --all -n boutique
