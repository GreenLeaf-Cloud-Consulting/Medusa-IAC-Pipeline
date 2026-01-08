# 🚀 Guide de Déploiement - Architecture V2

> Architecture professionnelle multi-région avec Application Load Balancers et bases de données répliquées

## 📋 Table des Matières

1. [Vue d'ensemble](#-vue-densemble)
2. [Architecture](#-architecture)
3. [Prérequis](#-prérequis)
4. [Déploiement Terraform](#-déploiement-terraform)
5. [Configuration Ansible](#-configuration-ansible)
6. [Vérifications](#-vérifications)
7. [Troubleshooting](#-troubleshooting)

---

## 🎯 Vue d'ensemble

### Composants déployés

**France (eu-west-3 - Paris)**
- 1x Application Load Balancer
- 2x EC2 App instances (t2.small)
- 1x PostgreSQL Primary (t2.medium)
- 1x PostgreSQL Replica (t2.small)

**Germany (eu-central-1 - Frankfurt)**
- 1x Application Load Balancer
- 2x EC2 App instances (t2.small)
- 1x PostgreSQL Replica (t2.small)

### Coût estimé
~$209/mois (voir [ARCHITECTURE-FINALE.md](ARCHITECTURE-FINALE.md))

---

## 🏗 Architecture

```
                        ┌─────────────────────────────────┐
                        │         INTERNET                │
                        └─────────────┬───────────────────┘
                                      │
                    ┌─────────────────┴────────────────────┐
                    │                                      │
            ┌───────▼────────┐                    ┌───────▼────────┐
            │  ALB France    │                    │  ALB Germany   │
            │  (eu-west-3)   │                    │ (eu-central-1) │
            └───────┬────────┘                    └───────┬────────┘
                    │                                     │
         ┌──────────┴──────────┐               ┌─────────┴─────────┐
         │                     │               │                   │
    ┌────▼─────┐         ┌────▼─────┐    ┌───▼──────┐      ┌────▼──────┐
    │ App 1    │         │ App 2    │    │ App 1    │      │ App 2     │
    │ France   │         │ France   │    │ Germany  │      │ Germany   │
    └────┬─────┘         └────┬─────┘    └────┬─────┘      └────┬──────┘
         │                    │               │                  │
         └──────┬─────────────┘               └────────┬─────────┘
                │                                      │
         ┌──────▼───────┐                      ┌──────▼──────┐
         │              │                      │             │
    ┌────▼─────┐  ┌────▼─────┐          ┌─────▼──────┐      │
    │ DB       │  │ DB       │          │ DB         │      │
    │ Primary  ├──► Replica  │◄─────────┤ Replica    │      │
    │ France   │  │ France   │          │ Germany    │      │
    └──────────┘  └──────────┘          └────────────┘      │
                                                             │
                        Streaming Replication ──────────────┘
```

---

## ✅ Prérequis

### 1. Outils requis

```bash
# Terraform
terraform --version  # >= 1.0

# Ansible
ansible --version    # >= 2.9

# AWS CLI (optionnel mais recommandé)
aws --version
```

### 2. Credentials AWS

Configurer les credentials AWS:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-west-3"
```

Ou via `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
```

### 3. Variables d'environnement Ansible

Créer le fichier `.env` dans `terraform/ansible/`:

```bash
# GitHub Authentication
GITHUB_ACCESS_TOKEN=ghp_your_token_here

# Medusa Security
MEDUSA_JWT_SECRET=your-super-secret-jwt-key-here
MEDUSA_COOKIE_SECRET=your-super-secret-cookie-key-here
```

---

## 🚀 Déploiement Terraform

### Étape 1: Initialiser Terraform

```bash
cd terraform/
terraform init
```

### Étape 2: Planifier le déploiement

```bash
terraform plan
```

Vérifier que le plan affiche:
- ✅ 2 VPCs (France + Germany)
- ✅ 2 ALBs
- ✅ 4 App instances
- ✅ 3 DB instances
- ✅ Security Groups
- ✅ Subnets & Route Tables

### Étape 3: Appliquer l'infrastructure

```bash
# Option 1: Apply avec confirmation
terraform apply

# Option 2: Apply sans confirmation
terraform apply -auto-approve
```

⏱️ **Durée**: ~5-10 minutes

### Étape 4: Récupérer les outputs

```bash
# Voir les URLs des ALB
terraform output france_alb_url
terraform output germany_alb_url

# Voir les IPs des instances
terraform output france_app_instances
terraform output germany_app_instances
```

### Étape 5: Vérifier l'inventory Ansible

```bash
cat ansible/inventory/hosts.yml
```

L'inventory doit contenir:
- ✅ france-prod-app-1
- ✅ france-prod-app-2
- ✅ france-prod-db-primary
- ✅ france-prod-db-replica-1
- ✅ germany-prod-app-1
- ✅ germany-prod-app-2
- ✅ germany-prod-db-replica-1

---

## ⚙️ Configuration Ansible

### Étape 1: Tester la connectivité

```bash
cd ansible/

# Tester TOUTES les instances
ansible all -i inventory/hosts.yml -m ping

# Tester seulement les app instances
ansible medusa_app -i inventory/hosts.yml -m ping

# Tester seulement les databases
ansible databases -i inventory/hosts.yml -m ping
```

### Étape 2: Déployer PostgreSQL

```bash
# Déployer d'abord le Primary
ansible-playbook -i inventory/hosts.yml site.yml --tags postgresql --limit database_primary

# Attendre 2 minutes, puis déployer les Replicas
sleep 120
ansible-playbook -i inventory/hosts.yml site.yml --tags postgresql --limit database_replicas
```

### Étape 3: Déployer Medusa

```bash
# Déployer sur TOUTES les app instances
ansible-playbook -i inventory/hosts.yml site.yml --tags medusa
```

### Étape 4: Déploiement complet (tout en une fois)

```bash
# Si vous voulez tout déployer d'un coup:
ansible-playbook -i inventory/hosts.yml site.yml
```

---

## 🔍 Vérifications

### 1. Vérifier les ALBs

```bash
# France
curl http://$(terraform output -raw france_alb_url)/health

# Germany
curl http://$(terraform output -raw germany_alb_url)/health
```

Réponse attendue: `200 OK`

### 2. Vérifier PostgreSQL

```bash
# Se connecter au Primary
ssh -i keys/prod-france-db-key.pem admin@<PRIMARY_IP>

# Vérifier PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"

# Vérifier la réplication
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

### 3. Vérifier Medusa

```bash
# Se connecter à une app instance
ssh -i keys/prod-france-app-1-key.pem admin@<APP_IP>

# Vérifier Docker
docker ps

# Vérifier les logs Medusa
cd ~/medusa
docker-compose logs -f medusa
```

### 4. Vérifier Target Groups (ALB)

Dans la console AWS:
1. EC2 → Load Balancers → Sélectionner l'ALB
2. Target Groups → Vérifier que les instances sont "healthy"

---

## 🛠 Troubleshooting

### Problème: Instances ne sont pas "healthy" dans l'ALB

**Solution**:

```bash
# Vérifier que Medusa écoute sur le bon port
ssh -i keys/prod-france-app-1-key.pem admin@<APP_IP>
netstat -tulpn | grep 9000

# Vérifier les Security Groups
# L'app doit autoriser le trafic du Security Group de l'ALB sur le port 9000
```

### Problème: Réplication PostgreSQL ne fonctionne pas

**Solution**:

```bash
# Sur le Primary, vérifier pg_hba.conf
sudo cat /etc/postgresql/15/main/pg_hba.conf | grep replication

# Vérifier postgresql.conf
sudo cat /etc/postgresql/15/main/postgresql.conf | grep wal_level

# Redémarrer PostgreSQL
sudo systemctl restart postgresql
```

### Problème: Cannot connect to GitHub

**Solution**:

```bash
# Vérifier le token GitHub
echo $GITHUB_ACCESS_TOKEN

# Tester manuellement
git clone https://${GITHUB_ACCESS_TOKEN}@github.com/GreenLeaf-Cloud-Consulting/Aws-Medusa-Infra.git
```

### Problème: Terraform apply échoue

**Solution**:

```bash
# Nettoyer l'état
terraform destroy -auto-approve

# Réinitialiser
rm -rf .terraform/ .terraform.lock.hcl
terraform init
terraform apply
```

---

## 📊 Monitoring

### Logs Terraform

```bash
export TF_LOG=DEBUG
terraform apply
```

### Logs Ansible

```bash
ansible-playbook -vvv -i inventory/hosts.yml site.yml
```

### Logs Application

```bash
# App instances
docker-compose -f ~/medusa/docker-compose.yml logs -f

# PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## 🔐 Sécurité

### Clés SSH

Les clés SSH sont automatiquement générées et sauvegardées dans `terraform/keys/`:

```
keys/
├── prod-france-app-1-key.pem
├── prod-france-app-2-key.pem
├── prod-france-db-key.pem
├── prod-germany-app-1-key.pem
├── prod-germany-app-2-key.pem
└── prod-germany-db-key.pem
```

⚠️ **IMPORTANT**: Ne JAMAIS commit ces clés dans Git!

### Rotation des secrets

Modifier `.env` et relancer Ansible:

```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags medusa
```

---

## 🎉 Déploiement réussi!

Après avoir suivi ce guide, vous devriez avoir:

✅ 2 régions AWS opérationnelles (France + Germany)
✅ 2 ALBs distribuant le trafic sur 4 instances
✅ 3 instances PostgreSQL avec réplication streaming
✅ Medusa déployé et accessible via les ALBs
✅ Infrastructure hautement disponible

**URLs d'accès**:
- France: http://<FRANCE_ALB_DNS>
- Germany: http://<GERMANY_ALB_DNS>

---

## 📚 Documentation supplémentaire

- [ARCHITECTURE-FINALE.md](ARCHITECTURE-FINALE.md) - Vue d'ensemble de l'architecture
- [ansible/README.md](ansible/README.md) - Documentation Ansible
- [ansible/QUICKSTART.md](ansible/QUICKSTART.md) - Guide rapide Ansible

---

**Besoin d'aide?** Créer une issue sur GitHub ou contacter l'équipe DevOps.
