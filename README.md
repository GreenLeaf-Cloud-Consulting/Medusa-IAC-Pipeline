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
   │ EKS (x2)    │           │ CloudWatch  │           │ CloudWatch   │
   │ CloudWatch  │           │ Monitoring  │           │ Monitoring   │
   │ Monitoring  │           └─────────────┘           └──────────────┘
   └─────────────┘

   CloudWatch Alarms ──► SNS Topic ──► Lambda ──► Discord
   Prometheus + Grafana ◄── node_exporter (sur chaque EC2)
```

## Prérequis

- [Terraform](https://terraform.io) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configuré
- [kubectl](https://kubernetes.io/docs/tasks/tools/) pour EKS
- [k6](https://k6.io) pour les tests de charge

## Configuration

Copier `terraform.tfvars.example` vers `terraform.tfvars` et adapter les valeurs :

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Puis remplir les variables dans `terraform.tfvars` :

```hcl
discord_webhook        = "https://discord.com/api/webhooks/xxx/yyy"
grafana_admin_password = "un_mot_de_passe_securise"
```

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `discord_webhook` | URL du webhook Discord pour recevoir les alertes CloudWatch | Oui |
| `grafana_admin_password` | Mot de passe admin Grafana (default: `admin`) | Non |

> Le fichier `terraform.tfvars` est ignoré par git (`.gitignore`), vos secrets ne seront jamais commités.

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
│   ├── terraform.tfvars.example       # Exemple de configuration
│   ├── load-aws-credentials.sh        # Chargement des credentials
│   ├── modules/
│   │   ├── vpc/                       # Réseau
│   │   ├── alb/                       # Load Balancer
│   │   ├── ec2-instance/              # Instances applicatives
│   │   ├── database/                  # PostgreSQL (primary + replica)
│   │   ├── s3/                        # Stockage assets
│   │   ├── eks/                       # Cluster Kubernetes
│   │   ├── cloudwatch/                # CloudWatch alertes + Lambda Discord
│   │   ├── monitoring/                # Prometheus + Grafana
│   │   └── environments/
│   │       ├── france/prod/
│   │       ├── germany/prod/
│   │       └── sweden/prod/
│   └── ansible/                       # Configuration des serveurs
└── k6/
    └── load-test.js                   # Test de charge 1000 utilisateurs
```

## Monitoring

### CloudWatch
Surveille les metriques EC2 de chaque region. Quand un seuil est depasse, une alerte est envoyee sur Discord via une Lambda Python.

| Metrique | Seuil | Periode |
|----------|-------|---------|
| CPUUtilization | > 70% | 5 min |
| NetworkIn | > 5 MB | 5 min |
| NetworkOut | > 5 MB | 5 min |
| EBSWriteOps | > 3000 IOPS | 1 min |
| EBSWriteBytes | > 100 MB | 1 min |
| StatusCheckFailed | >= 1 | 5 min |

### Prometheus + Grafana
- **node_exporter** tourne sur chaque EC2 applicative (installe via `user_data`) et expose les metriques sur le port 9100
- **Prometheus** scrape ces metriques toutes les 15 secondes
- **Grafana** affiche les donnees avec le dashboard "Node Exporter Full"

### Acces apres deploiement
- **Grafana** : `http://<monitoring-public-ip>:3000` (login: admin / mot de passe defini dans `terraform.tfvars`)
- **Prometheus** : `http://<monitoring-public-ip>:9090`
- Les URLs exactes sont affichees dans les outputs apres `terraform apply`

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
