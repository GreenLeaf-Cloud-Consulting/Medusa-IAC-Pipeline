# ADR-002 : Déploiement Multi-AZ (3 zones)

**Date** : 2026-03-15  
**Statut** : Accepté

## Contexte

AWS peut subir des pannes sur une AZ. Le cahier des charges exige une haute disponibilité pour simuler un scénario Black Friday.

## Décision

Déploiement sur **3 AZs** : eu-west-3a, eu-west-3b, eu-west-3c.

## Justification

- Une panne AZ unique ne coupe pas le service (2/3 AZs restent up)
- Le Cluster Autoscaler répartit les nodes équitablement entre les AZs
- L'ELB distribue le trafic automatiquement entre les AZs disponibles
- Coût marginal : les subnets supplémentaires ne coûtent rien

## Conséquences

- **Positif** : SLA 99.9%+ même en cas de panne AZ
- **Positif** : Pas de SPOF (Single Point of Failure) sur l'infra
- **Négatif** : Trafic inter-AZ facturé ($0.01/GB) — négligeable pour ce projet
