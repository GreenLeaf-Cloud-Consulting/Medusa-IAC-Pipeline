# Online Boutique — IAC Pipeline

Infrastructure AWS pour déployer **Online Boutique** (application e-commerce Google, 11 microservices) sur EKS, provisionnée avec Terraform et testée avec k6.

## Architecture

```
                        INTERNET
                            │
                            ▼
           ┌─────────────────────────────────┐
           │  ELB  (créé par Kubernetes)     │
           │  port 80  →  frontend service   │
           └────────────────┬────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                  AWS  eu-west-3  (Paris)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                VPC  10.0.0.0/16                      │   │
│  │                                                      │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐      │   │
│  │  │ eu-west-3a │  │ eu-west-3b │  │ eu-west-3c │      │   │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘      │   │
│  │        └───────────────┼───────────────┘             │   │
│  │                        │                             │   │
│  │   ┌────────────────────▼──────────────────────────┐  │   │
│  │   │     EKS  prod-france-eks-rayane               │  │   │
│  │   │     t3.large  │  min 1 — desired 2 — max 6   │  │   │
│  │   │                                               │  │   │
│  │   │   ┌───────────────────────────────────────┐   │  │   │
│  │   │   │          Online Boutique              │   │  │   │
│  │   │   │                                       │   │  │   │
│  │   │   │  frontend          HPA  2 → 20 pods   │   │  │   │
│  │   │   │  cartservice       HPA  2 → 15 pods   │   │  │   │
│  │   │   │  productcatalog    HPA  2 → 15 pods   │   │  │   │
│  │   │   │  checkoutservice   HPA  2 → 12 pods   │   │  │   │
│  │   │   │  currencyservice   HPA  2 → 12 pods   │   │  │   │
│  │   │   │  recommendation    HPA  2 → 12 pods   │   │  │   │
│  │   │   │  redis-cart        (sessions panier)  │   │  │   │
│  │   │   │  adservice                            │   │  │   │
│  │   │   │  emailservice                         │   │  │   │
│  │   │   │  paymentservice                       │   │  │   │
│  │   │   │  shippingservice                      │   │  │   │
│  │   │   └───────────────────────────────────────┘   │  │   │
│  │   │   metrics-server  +  cluster-autoscaler        │  │   │
│  │   └───────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  S3  eu-west-1 (Ireland) — assets storage                  │
└─────────────────────────────────────────────────────────────┘
```

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

Le déploiement prend ~15 minutes (EKS surtout).

### 3. Online Boutique sur EKS

```bash
cd ..
bash deploy.sh
```

Le script :
- Configure kubectl
- Fixe le hop limit IMDS sur les nodes
- Déploie metrics-server + cluster-autoscaler
- Déploie les 11 microservices + HPA
- Affiche l'URL du frontend

### 4. Test de charge

```bash
k6 run -e FRONTEND_URL=http://<ELB_URL> k6/load-test.js
```

Scénario Black Friday :

| Phase     | VUs    | Durée |
|-----------|--------|-------|
| Warm-up   | 1 000  | 2 min |
| Palier 1  | 5 000  | 8 min |
| Palier 2  | 20 000 | 8 min |
| Descente  | 0      | 3 min |

SLA : p95 < 2s, taux d'erreur < 1%

## Structure du projet

```
├── terraform/
│   ├── main.tf                       # Point d'entrée
│   ├── variables.tf
│   ├── load-aws-credentials.sh
│   └── modules/
│       ├── vpc/                      # VPC 3 AZs
│       ├── eks/                      # Cluster Kubernetes
│       ├── s3/                       # Stockage assets
│       └── environments/
│           ├── france/prod/          # Région active
│           ├── germany/prod/         # Désactivée (à décommenter)
│           └── sweden/prod/          # Désactivée (à décommenter)
├── k8s/
│   ├── online-boutique/
│   │   ├── namespace.yaml
│   │   ├── manifests.yaml            # 11 microservices
│   │   └── hpa.yaml                  # Auto-scaling pods
│   ├── metrics-server.yaml
│   └── cluster-autoscaler.yaml
├── k6/
│   ├── load-test.js                  # Test de charge Black Friday
│   └── results/summary.json
└── deploy.sh                         # Script de déploiement K8s
```

## Scaling

**Pods (HPA)** — déclenché à 60% CPU :

| Service           | Min | Max |
|-------------------|-----|-----|
| frontend          | 2   | 20  |
| cartservice       | 2   | 15  |
| productcatalog    | 2   | 15  |
| checkoutservice   | 2   | 12  |
| currencyservice   | 2   | 12  |
| recommendation    | 2   | 12  |

**Nodes (Cluster Autoscaler)** — 1 à 6 × t3.large (2 vCPU, 8 GB)

## Économiser sur les coûts

Scaler down quand tu ne travailles pas :

```bash
# Scale down
aws eks update-nodegroup-config \
  --cluster-name prod-france-eks-rayane \
  --nodegroup-name prod-france-eks-ng-rayane \
  --scaling-config minSize=0,maxSize=6,desiredSize=0 \
  --region eu-west-3

# Scale up
aws eks update-nodegroup-config \
  --cluster-name prod-france-eks-rayane \
  --nodegroup-name prod-france-eks-ng-rayane \
  --scaling-config minSize=1,maxSize=6,desiredSize=2 \
  --region eu-west-3
```

## Détruire l'infrastructure

```bash
cd terraform
source load-aws-credentials.sh
terraform destroy
```
