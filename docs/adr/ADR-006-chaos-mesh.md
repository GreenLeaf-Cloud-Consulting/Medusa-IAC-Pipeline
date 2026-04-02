ADR-006 - Chaos Engineering avec Chaos Mesh

Date : avril 2026
Statut : validé

Pour tester la résilience avant la démo on avait le choix entre AWS FIS (Fault Injection Simulator) et Chaos Mesh.

On a pris Chaos Mesh parce que c'est plus simple à utiliser sur Kubernetes. AWS FIS c'est plutôt pour simuler des pannes au niveau infra AWS (arrêter une AZ, throttler une API), nous on voulait tester au niveau des pods directement.

Les expériences qu'on a préparées :

1. Tuer un pod cartservice toutes les 30s - pour vérifier que le 2ème replica prend bien le relais
2. Tuer un pod recommendationservice - pour voir si la homepage reste accessible en mode dégradé
3. Ajouter 200ms de latence sur productcatalogservice - pour voir l'impact sur la latence globale
4. Stresser le CPU du frontend à 80% - pour déclencher le HPA

Ce qu'on a observé : quand on tue le cartservice, le site reste accessible. Kubernetes recrée le pod en moins de 30 secondes. C'est exactement ce qu'on voulait vérifier avant le Black Friday où le formateur va injecter des pannes en live.
