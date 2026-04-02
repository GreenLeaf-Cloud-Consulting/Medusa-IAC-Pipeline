# ADR-007 : Stratégie Spot Instances pour FinOps

**Date** : 2026-04-02  
**Statut** : Accepté

## Contexte

Les tests de charge nécessitent jusqu'à 6-8 nodes EC2 t3.large. En On-Demand, le coût est ~$0.094/h par node. Sur une semaine de tests intensifs, la facture EC2 peut dépasser le budget alloué.

## Décision

Architecture **hybride On-Demand + Spot** avec deux node groups distincts.

## Architecture

```
Node group On-Demand (prod-france-eks-ng-rayane)
  - Instance : t3.large
  - min: 1 / desired: 2 / max: 6
  - Usage : services critiques, toujours disponibles
  - Prix : ~$0.094/h

Node group Spot (prod-france-eks-ng-spot-rayane)
  - Instances : t3.large, t3a.large, t2.large (fallback)
  - min: 0 / desired: 0 / max: 4
  - Usage : absorption des pics de charge
  - Prix : ~$0.028/h (~70% moins cher)
```

## Justification

- Les Spot peuvent être interrompus avec 2 min de préavis → acceptables pour des workloads sans état (microservices stateless)
- 3 types d'instances en fallback (t3.large, t3a.large, t2.large) → réduit le risque d'interruption simultanée
- Le Cluster Autoscaler scale les Spot en premier pour minimiser les coûts
- Les nodes Spot ont un taint `spot=true:NoSchedule` → seuls les pods avec toleration y sont schedulés

## Économies estimées

| Scénario | On-Demand seul | Hybride (2 OD + 4 Spot) |
|---|---|---|
| 6 nodes, 8h de test | ~$4.5 | ~$2.4 |
| 6 nodes, 1 semaine | ~$95 | ~$50 |

## Conséquences

- **Positif** : ~50% d'économies sur les tests de charge
- **Positif** : Cluster Autoscaler gère automatiquement le mix On-Demand/Spot
- **Négatif** : En cas d'interruption Spot, les pods sont évictés → quelques secondes d'impact
- **Mitigation** : PodDisruptionBudget + réplicas >= 2 sur tous les services critiques
