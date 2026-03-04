# Medusa IAC Pipeline

Infrastructure AWS multi-région pour une application e-commerce Medusa, déployée avec Terraform.

## Architecture

```
                        ┌─────────────────────────────────┐
                        │         S3 (eu-west-1)          │
                        │    jugurta-prod-medusa-assets    │
                        └────────────┬────────────────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
   ┌──────▼──────┐           ┌───────▼─────┐           ┌───────▼──────┐
   │   FRANCE    │           │   GERMANY   │           │   SWEDEN     │
   │  eu-west-2  │           │ eu-central-1│           │  eu-north-1  │
   ├─────────────┤           ├─────────────┤           ├──────────────┤
   │ ALB         │           │ ALB         │           │ ALB          │
   │ EC2 x2      │           │ EC2 x2      │           │ EC2 x2       │
   │ DB Primary  │           │ DB Replica  │           │ DB Replica   │
   │ DB Replica  │           │ EKS (x2)    │           │ EKS (x2)     │
   │ EKS (x2)    │           └─────────────┘           └──────────────┘
   │ CloudWatch  │
   └─────────────┘
```

## Prérequis

- [Terraform](https://terraform.io) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configuré
- [kubectl](https://kubernetes.io/docs/tasks/tools/) pour EKS
- [k6](https://k6.io) pour les tests de charge

## Lancer le projet

### 1. Configurer les credentials AWS

Créez un fichier `terraform/.env` :
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=eu-west-2
```

Puis chargez-les :
```bash
cd terraform
source load-aws-credentials.sh
```

### 2. Déployer l'infrastructure

```bash
terraform init
terraform plan
terraform apply
```

> Le déploiement prend environ 20-25 minutes (EKS surtout).

### 3. Configurer kubectl

```bash
# France
aws eks update-kubeconfig --region eu-west-2 --name prod-france-eks-rayane

# Germany
aws eks update-kubeconfig --region eu-central-1 --name prod-germany-eks-rayane

# Sweden
aws eks update-kubeconfig --region eu-north-1 --name prod-sweden-eks-rayane

# Vérifier les nodes
kubectl get nodes
```

### 4. Lancer les tests de charge

```bash
cd ..
k6 run k6/load-test.js
```

## Structure du projet

```
├── terraform/
│   ├── main.tf                        # Point d'entrée principal
│   ├── variables.tf
│   ├── load-aws-credentials.sh        # Chargement des credentials
│   ├── modules/
│   │   ├── vpc/                       # Réseau
│   │   ├── alb/                       # Load Balancer
│   │   ├── ec2-instance/              # Instances applicatives
│   │   ├── database/                  # PostgreSQL (primary + replica)
│   │   ├── s3/                        # Stockage assets
│   │   ├── eks/                       # Cluster Kubernetes
│   │   ├── cloudwatch/                # Monitoring + alertes
│   │   └── environments/
│   │       ├── france/prod/
│   │       ├── germany/prod/
│   │       └── sweden/prod/
│   └── ansible/                       # Configuration des serveurs
└── k6/
    └── load-test.js                   # Test de charge 1000 utilisateurs
```

## Régions déployées

| Région | Code AWS | Rôle DB |
|--------|----------|---------|
| France | eu-west-2 | Primary |
| Germany | eu-central-1 | Replica |
| Sweden | eu-north-1 | Replica |

## Détruire l'infrastructure

```bash
cd terraform
source load-aws-credentials.sh
terraform destroy
```
