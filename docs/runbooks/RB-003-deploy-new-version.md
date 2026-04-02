# Runbook RB-003 : Déployer une nouvelle version

**Déclencheur** : Nouvelle version d'un microservice à déployer  
**Durée estimée** : 5 minutes (rolling update)

## Pré-requis

- Image Docker disponible dans le registry
- Tests passés en staging

## Procédure

### 1. Mettre à jour le tag de l'image

Dans `k8s/online-boutique/manifests.yaml`, changer le tag :

```yaml
image: us-central1-docker.pkg.dev/google-samples/microservices-demo/frontend:v0.10.6  # nouveau tag
```

### 2. Appliquer le déploiement

```bash
kubectl apply -f k8s/online-boutique/manifests.yaml
```

### 3. Surveiller le rolling update

```bash
kubectl rollout status deployment/frontend -n boutique --timeout=120s
```

Kubernetes fait un **rolling update** : il crée les nouveaux pods avant de supprimer les anciens. Zéro downtime.

### 4. Vérifier

```bash
kubectl get pods -n boutique -l app=frontend
# Les pods doivent être Running avec l'AGE récente
```

Tester manuellement le site.

## Rollback

Si problème détecté :

```bash
kubectl rollout undo deployment/frontend -n boutique
kubectl rollout status deployment/frontend -n boutique
```

Kubernetes revient automatiquement à la version précédente.

## Vérification post-déploiement

- [ ] Error rate < 1% sur Grafana
- [ ] p95 latency dans les normes
- [ ] Traces Jaeger sans erreurs
- [ ] Pods en Running depuis > 2 minutes
