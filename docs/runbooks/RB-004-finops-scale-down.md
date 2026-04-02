# Runbook RB-004 : FinOps - Scale down en fin de journée

**Déclencheur** : Fin de session de travail / nuit / week-end  
**Économies** : ~$3-5/heure en supprimant les nodes EC2

## Coûts de référence

| Configuration | Coût/heure |
|---|---|
| 6x t3.large (test de charge) | ~$0.83/h |
| 2x t3.large (mode normal) | ~$0.28/h |
| 0 nodes (scale down) | ~$0.10/h (control plane EKS seulement) |

## Scale down complet (nuit/week-end)

```bash
bash scale.sh down
```

Cela :
1. Scale tous les deployments à 0 replicas
2. Réduit le nodegroup à 0 nodes

**Important** : Le control plane EKS continue de tourner ($0.10/h = ~$2.4/jour).

## Redémarrage le lendemain

```bash
bash scale.sh normal         # Remet 2 nodes
kubectl apply -f k8s/online-boutique/manifests.yaml  # Recrée les pods
kubectl apply -f k8s/monitoring/                      # Recrée monitoring
```

Attendre ~3 minutes que les nodes soient `Ready`.

## Scale down partiel (pause courte)

Si on revient dans moins de 2h, juste scale down les nodes sans toucher les pods :

```bash
aws eks update-nodegroup-config \
  --cluster-name prod-france-eks-rayane \
  --nodegroup-name prod-france-eks-ng-rayane \
  --scaling-config minSize=0,maxSize=10,desiredSize=1 \
  --region eu-west-3
```

## Destruction complète (fin de projet)

```bash
cd terraform
terraform destroy -auto-approve
```

**ATTENTION** : Irréversible. Détruit tout (EKS, VPC, WAF, S3).

## Rappel des coûts AWS mensuels estimés

- EKS control plane : $73/mois
- 2x t3.large (24h/j) : ~$200/mois
- ELB : ~$20/mois
- **Total si allumé H24** : ~$300/mois

**Bonne pratique** : Éteindre les nodes la nuit → économiser ~60% du coût EC2.
