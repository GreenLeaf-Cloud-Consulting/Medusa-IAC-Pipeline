ADR-001 - Pourquoi on est passé à EKS plutôt que rester sur EC2

Date : mars 2026
Statut : validé

Au départ on avait une archi EC2 classique avec deux serveurs app (App-1, App-2), une base PostgreSQL et un ALB devant. Ca marchait mais dès qu'on a voulu scaler pour les tests de charge, c'était galère. Fallait manuellement changer les instances, redéployer, etc.

On a donc décidé de migrer vers EKS pour plusieurs raisons :

- Le HPA (Horizontal Pod Autoscaler) gère le scaling des pods automatiquement selon le CPU. Sur EC2 on aurait dû scripter ça nous-mêmes.
- Le Cluster Autoscaler ajoute/supprime des nodes EC2 selon la charge. Pendant les tests à 20K users on a vu ça en action, les nodes se sont ajoutés tout seuls.
- Les rolling updates sont gérés nativement, pas besoin de script de déploiement custom.
- Pour 11 microservices, gérer ça sur EC2 avec Docker Compose c'était pas tenable.

Ce qu'on perd : EKS coûte $0.10/h juste pour le control plane, même quand y'a rien qui tourne. Sur EC2 on payait seulement quand les instances tournaient.

Mais pour le Black Friday et les tests de charge progressifs jusqu'à 90K users, EKS était clairement le bon choix.
