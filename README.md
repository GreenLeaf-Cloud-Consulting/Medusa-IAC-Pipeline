# Online Boutique — IAC Pipeline

Infrastructure AWS complète pour déployer **Online Boutique** (application e-commerce Google composée de 11 microservices) sur EKS, provisionnée entièrement avec Terraform et testée avec k6.

## Architecture

```
                        INTERNET
                            │
                            ▼
           ┌─────────────────────────────────┐
           │     AWS ELB (créé par K8s)      │
           │     port 80 → frontend          │
           └────────────────┬────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                    AWS eu-west-3 (Paris)                          │
│                                                                   │
│  WAF v2 ──────────────────────────────────────────────────────   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    VPC  10.0.0.0/16                         │  │
│  │                                                             │  │
│  │   eu-west-3a        eu-west-3b        eu-west-3c            │  │
│  │   10.0.1.0/24       10.0.2.0/24       10.0.3.0/24          │  │
│  │   (public)          (public)          (public)             │  │
│  │   10.0.11.0/24      10.0.12.0/24      10.0.13.0/24         │  │
│  │   (private)         (private)         (private)            │  │
│  │                                                             │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │          EKS  prod-france-eks-rayane                 │   │  │
│  │  │    t3.large · min 1 · desired 3 · max 10 nodes       │   │  │
│  │  │    + spot nodes (max 4) pour les pics de charge      │   │  │
│  │  │                                                      │   │  │
│  │  │   ┌──────────────────────────────────────────────┐   │   │  │
│  │  │   │   namespace: boutique                        │   │   │  │
│  │  │   │                                              │   │   │  │
│  │  │   │   frontend          HPA  2 → 40 pods         │   │   │  │
│  │  │   │   cartservice       HPA  2 → 30 pods         │   │   │  │
│  │  │   │   productcatalog    HPA  2 → 30 pods         │   │   │  │
│  │  │   │   checkoutservice   HPA  2 → 25 pods         │   │   │  │
│  │  │   │   currencyservice   HPA  2 → 25 pods         │   │   │  │
│  │  │   │   recommendation    HPA  2 → 25 pods         │   │   │  │
│  │  │   │   redis-cart        (panier en mémoire)      │   │   │  │
│  │  │   │   adservice                                  │   │   │  │
│  │  │   │   emailservice                               │   │   │  │
│  │  │   │   paymentservice                             │   │   │  │
│  │  │   │   shippingservice                            │   │   │  │
│  │  │   └──────────────────────────────────────────────┘   │   │  │
│  │  │                                                      │   │  │
│  │  │   ┌──────────────────────────────────────────────┐   │   │  │
│  │  │   │   namespace: monitoring                      │   │   │  │
│  │  │   │   Prometheus + Grafana + AlertManager        │   │   │  │
│  │  │   └──────────────────────────────────────────────┘   │   │  │
│  │  │                                                      │   │  │
│  │  │   ┌──────────────────────────────────────────────┐   │   │  │
│  │  │   │   namespace: amazon-cloudwatch               │   │   │  │
│  │  │   │   CloudWatch Agent (1 par node)              │   │   │  │
│  │  │   │   Fluent Bit (logs)                          │   │   │  │
│  │  │   └──────────────────────────────────────────────┘   │   │  │
│  │  │                                                      │   │  │
│  │  │   metrics-server  ·  cluster-autoscaler              │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  CloudWatch  →  SNS  →  Email (alertes CPU/mémoire/crashs)       │
│  Budget AWS  →  alerte à 600$/mois                               │
│                                                                   │
│  S3  eu-west-1 (Irlande)  —  bucket assets global               │
└───────────────────────────────────────────────────────────────────┘

   Germany eu-central-1  ┐
   Sweden  eu-north-1    ┘  modules Terraform prêts (à décommenter)
```

## Stack technique

| Couche | Technologie |
|---|---|
| IaC | Terraform >= 1.0 |
| Orchestration | AWS EKS (Kubernetes 1.31) |
| Application | Online Boutique — Google Microservices Demo |
| Monitoring | Prometheus + Grafana + CloudWatch Container Insights |
| Sécurité | WAF v2, RBAC, Network Policies, External Secrets Operator |
| Secrets | AWS Secrets Manager |
| Tests de charge | k6 |

## Prérequis

- [Terraform](https://terraform.io) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [k6](https://k6.io)

## Déploiement

### 1. Credentials AWS

```bash
cd terraform
source load-aws-credentials.sh
```

### 2. Infra Terraform

```bash
terraform init
terraform apply
```

Le déploiement prend environ 15 minutes, principalement à cause de la création du cluster EKS.

### 3. Online Boutique sur EKS

```bash
cd ..
bash deploy.sh
```

Le script configure kubectl, déploie le metrics-server, le cluster-autoscaler, les 11 microservices avec leurs HPA, et affiche l'URL du frontend à la fin.

### 4. Test de charge

Avant de lancer, scaler les nodes :

```bash
bash scale.sh up   # passe à 8 nodes
```

Puis lancer k6 :

```bash
k6 run -e FRONTEND_URL=http://<ELB_URL> k6/load-test.js
```

Scénario Black Friday :

| Phase | VUs | Durée |
|---|---|---|
| Warm-up | 1 000 | 2 min |
| Palier 1 | 5 000 | 8 min |
| Palier 2 | 20 000 | 8 min |
| Descente | 0 | 3 min |

SLA cible : p95 < 2s, taux d'erreur < 1%

## Autoscaling

### Pods — HPA (Horizontal Pod Autoscaler)

Déclenché à 60% CPU (70% mémoire pour le frontend) :

| Service | Min | Max |
|---|---|---|
| frontend | 2 | 40 |
| cartservice | 2 | 30 |
| productcatalogservice | 2 | 30 |
| checkoutservice | 2 | 25 |
| currencyservice | 2 | 25 |
| recommendationservice | 2 | 25 |

### Nodes — Cluster Autoscaler

- Node group on-demand : 1 à 10 × t3.large (2 vCPU, 8 GB RAM)
- Node group spot : jusqu'à 4 nodes (~70% moins chers) pour absorber les pics

Quand les pods sont en état `Pending` faute de ressources, le Cluster Autoscaler provisionne automatiquement de nouveaux nodes EC2. Quand la charge redescend, les nodes vides sont supprimés après 10 minutes.

## Sécurité

- **WAF v2** : protection contre les attaques web courantes (SQL injection, XSS...)
- **RBAC** : principe du moindre privilège — les comptes de service n'ont accès qu'à ce dont ils ont besoin
- **Network Policies** : par défaut tout le trafic entre pods est bloqué ; chaque microservice ne peut parler qu'à ses dépendances directes
- **External Secrets Operator** : les secrets (mots de passe, clés) sont stockés dans AWS Secrets Manager et synchronisés automatiquement dans Kubernetes toutes les heures — rien de sensible dans le code

## Monitoring

**Grafana** (dashboard visuel) :

```bash
kubectl get svc prometheus-grafana -n monitoring
# login: admin / mot de passe dans le secret prometheus-grafana
```

**CloudWatch Dashboard** : disponible dans la console AWS sous le nom `prod-france-eks-dashboard-rayane`

**Alertes email** configurées sur `jugurta1999@gmail.com` :
- CPU nodes > 80%
- Mémoire nodes > 80%
- Plus de 10 redémarrages de pods en 5 minutes

## Gestion des coûts

```bash
bash scale.sh up      # avant un test de charge → 8 nodes
bash scale.sh normal  # usage quotidien → 3 nodes
bash scale.sh down    # fin de journée → 0 nodes (économies max)
bash scale.sh status  # état actuel du cluster
```

Budget AWS configuré avec alerte à **600$/mois**.

## Structure du projet

```
├── terraform/
│   ├── main.tf                        # Point d'entrée (France active, Germany/Sweden commentés)
│   ├── provider.tf                    # Providers AWS (Paris + Irlande)
│   ├── variables.tf
│   ├── load-aws-credentials.sh
│   └── modules/
│       ├── vpc/                       # VPC + subnets + IGW (3 AZs)
│       ├── eks/                       # Cluster EKS + node groups + CloudWatch addon
│       ├── cloudwatch/                # Alarmes + dashboard + SNS alerts
│       ├── waf/                       # WAF v2
│       ├── budget/                    # Alerte budget AWS
│       ├── s3/                        # Bucket assets global
│       └── environments/
│           ├── france/prod/           # Région active — eu-west-3
│           ├── germany/prod/          # Prête — eu-central-1 (décommenter dans main.tf)
│           └── sweden/prod/           # Prête — eu-north-1 (décommenter dans main.tf)
├── k8s/
│   ├── online-boutique/
│   │   ├── namespace.yaml             # Namespace boutique
│   │   ├── manifests.yaml             # 11 microservices
│   │   └── hpa.yaml                   # Autoscaling pods
│   ├── security/
│   │   ├── rbac.yaml                  # Roles + Network Policies
│   │   └── external-secrets.yaml     # Connexion AWS Secrets Manager
│   ├── monitoring/                    # Prometheus + Grafana (Helm values)
│   ├── metrics-server.yaml
│   └── cluster-autoscaler.yaml
├── k6/
│   └── load-test.js                   # Scénario Black Friday
├── scale.sh                           # Gestion rapide du scaling
└── deploy.sh                          # Déploiement K8s complet
```

## Détruire l'infrastructure

```bash
cd terraform
source load-aws-credentials.sh
terraform destroy
```
