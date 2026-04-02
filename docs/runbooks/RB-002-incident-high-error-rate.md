# Runbook RB-002 : Incident - Taux d'erreur élevé

**Déclencheur** : Error rate > 5% sur le dashboard Grafana ou alerte  
**Sévérité** : P1 (impact utilisateur direct)

## Diagnostic rapide (< 2 minutes)

### 1. Vérifier les pods

```bash
kubectl get pods -n boutique
```

Chercher : `CrashLoopBackOff`, `OOMKilled`, `Pending`, `Error`

### 2. Identifier le service en erreur

```bash
kubectl logs -n boutique -l app=frontend --tail=50 | grep -i error
```

Aller dans **Jaeger UI** → sélectionner `frontend` → filtrer par `Error = true` pour identifier quel service downstream échoue.

### 3. Vérifier les ressources

```bash
kubectl top pods -n boutique
kubectl top nodes
```

Si CPU > 90% sur les nodes → problème de capacité.

## Actions correctives

### Cas A : Pods en CrashLoopBackOff

```bash
kubectl describe pod <pod-name> -n boutique
kubectl logs <pod-name> -n boutique --previous
```

Relancer si nécessaire :
```bash
kubectl rollout restart deployment/<service> -n boutique
```

### Cas B : Saturation CPU (> 90%)

```bash
bash scale.sh up   # Ajoute des nodes immédiatement
```

Le HPA va automatiquement créer plus de pods sur les nouveaux nodes.

### Cas C : Service spécifique en erreur

```bash
kubectl rollout restart deployment/<service-name> -n boutique
kubectl rollout status deployment/<service-name> -n boutique
```

### Cas D : Tous les pods OK mais erreurs persistantes

Vérifier les Network Policies :
```bash
kubectl get networkpolicy -n boutique
```

Vérifier l'ELB :
```bash
kubectl describe svc frontend-external -n boutique
```

## Escalade

Si non résolu en 15 minutes → scale up max + alerter l'équipe.

```bash
aws eks update-nodegroup-config \
  --cluster-name prod-france-eks-rayane \
  --nodegroup-name prod-france-eks-ng-rayane \
  --scaling-config minSize=6,maxSize=10,desiredSize=8 \
  --region eu-west-3
```
