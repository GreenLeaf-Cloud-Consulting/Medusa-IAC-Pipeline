# 👥 Guide de Travail en Équipe - Medusa IAC Pipeline

## 🎯 Problème

Quand plusieurs membres de l'équipe travaillent avec les mêmes credentials AWS et les mêmes variables Terraform, les ressources entrent en conflit car elles portent les mêmes noms :

- ALB (Application Load Balancer)
- Target Groups
- Security Groups
- VPC
- Instances EC2
- Bases de données

Cela cause des erreurs lors du déploiement et peut entraîner la suppression accidentelle de ressources d'un collègue.

## ✅ Solution

Chaque membre de l'équipe utilise un **préfixe personnel unique** pour toutes ses ressources.

Exemple :
- Alice déploie avec `personal_prefix = "alice"` → ses ressources s'appelleront `alice-dev-france-alb`
- Bob déploie avec `personal_prefix = "bob"` → ses ressources s'appelleront `bob-dev-france-alb`
- Jugurta déploie avec `personal_prefix = "jugurta"` → ses ressources s'appelleront `jugurta-dev-france-alb`

Comme ça, **zéro conflit** ! Chacun gère ses propres ressources.

## 🚀 Configuration Initiale

### 1. Créer votre fichier de configuration personnelle

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Modifier `terraform.tfvars`

Ouvrez le fichier `terraform.tfvars` créé et modifiez-le avec vos paramètres :

```hcl
# ==========================================
# CONFIGURATION PERSONNELLE
# ==========================================

# Utilisez votre prénom ou vos initiales
# Exemples: "alice", "bob", "jd", "marie", "jugurta"
personal_prefix = "votre-prenom"

# Environnement (gardez "dev" pour éviter les conflits)
# Options: "dev", "staging", "prod"
# ⚠️ Seul le responsable devrait utiliser "prod"
environment = "dev"
```

**Exemples concrets :**

```hcl
# Pour Alice
personal_prefix = "alice"
environment = "dev"

# Pour Bob
personal_prefix = "bob"
environment = "dev"

# Pour Jugurta
personal_prefix = "jugurta"
environment = "dev"
```

### 3. Charger les credentials AWS

```bash
source ./set-aws-credentials.sh
```

Ce script charge les credentials AWS depuis les variables d'environnement. Assurez-vous que les variables suivantes sont définies :

```bash
export AWS_ACCESS_KEY_ID="votre-clé"
export AWS_SECRET_ACCESS_KEY="votre-secret"
export AWS_DEFAULT_REGION="eu-west-3"
```

### 4. Initialiser et Déployer Terraform

```bash
# Première fois uniquement
terraform init

# Vérifier le plan (recommandé avant apply)
terraform plan

# Déployer vos ressources
terraform apply

# OU pour déployer sans confirmation
terraform apply -auto-approve
```

## 📋 Exemples de Noms de Ressources

### Configuration : Alice avec `environment = "dev"`

```
personal_prefix = "alice"
environment = "dev"
```

Ressources créées :
- **ALB France :** `alice-dev-france-alb`
- **ALB Germany :** `alice-dev-germany-alb`
- **Target Group France :** `alice-dev-france-medusa-tg`
- **Security Group ALB France :** `alice-dev-france-alb-sg`
- **VPC France :** `alice-dev-france-vpc`
- **EC2 App 1 France :** `alice-dev-app-1-app`
- **EC2 App 2 France :** `alice-dev-app-2-app`
- **Database Primary France :** `alice-dev-france-db-primary`
- **Database Replica France :** `alice-dev-france-db-replica-1`, `alice-dev-france-db-replica-2`

### Configuration : Bob avec `environment = "dev"`

```
personal_prefix = "bob"
environment = "dev"
```

Ressources créées (automatiquement avec préfixe `bob-dev-`) :
- `bob-dev-france-alb`
- `bob-dev-germany-alb`
- `bob-dev-france-medusa-tg`
- etc.

## 🔑 Clés SSH

Les clés SSH sont **automatiquement créées** et sauvegardées dans `terraform/keys/` avec le format :

```
{personal_prefix}-{environment}-{region}-{type}-key.pem
```

**Exemples :**

Avec `personal_prefix = "jugurta"` et `environment = "dev"` :

```
terraform/keys/
├── jugurta-dev-eu-west-2-app-1-key.pem      # App 1 France
├── jugurta-dev-eu-west-2-app-2-key.pem      # App 2 France
├── jugurta-dev-eu-central-1-app-1-key.pem   # App 1 Germany
├── jugurta-dev-eu-central-1-app-2-key.pem   # App 2 Germany
├── jugurta-dev-france-db-key.pem             # Database France
├── jugurta-dev-france-replica-db-key.pem     # Replicas France
└── jugurta-dev-germany-db-key.pem            # Database Germany
```

Ces clés **doivent rester privées** et ne doivent **jamais** être committées (ils sont dans `.gitignore`).

## 🐳 Déploiement Ansible

Une fois Terraform a créé les ressources, l'inventaire Ansible est **automatiquement généré** :

```bash
cd ansible

# Vérifier la connectivité SSH
ansible all -i inventory/hosts.yml -m ping

# Lancer le déploiement Medusa
./deploy.sh

# OU si vous avez créé des ressources avec "prod", lancez :
./deploy.sh
```

L'inventaire Ansible utilise automatiquement :
1. Les IPs générées par Terraform
2. Les clés SSH correspondant à votre `personal_prefix` et `environment`
3. Les noms d'hôtes générés avec votre préfixe

## 🧹 Nettoyage

Pour **supprimer vos ressources** (à faire avant de partir) :

```bash
cd terraform
source ./set-aws-credentials.sh
terraform destroy
```

⚠️ **Attention !** Cela supprimera **toutes les ressources** créées par votre déploiement.

## ⚠️ Important

### À faire

✅ Utilisez votre `personal_prefix` unique
✅ Utilisez `environment = "dev"` pour le développement
✅ Changez régulièrement vos credentials AWS pour la sécurité
✅ Supprimez vos ressources après tests
✅ Vérifiez le `terraform plan` avant `terraform apply`

### À ne PAS faire

❌ Ne committez **jamais** `terraform.tfvars`
❌ Ne committez **jamais** les clés SSH dans `terraform/keys/`
❌ Ne partez **jamais** vos credentials AWS
❌ N'utilisez **pas** `environment = "prod"` sauf directive du responsable
❌ Ne supprimez **pas** les ressources d'un collègue sur AWS Console

## 📚 Dépannage

### Erreur : `no such identity: ../keys/...-db-key.pem`

**Cause :** La clé SSH n'existe pas ou le chemin est incorrect.

**Solution :**

```bash
# 1. Vérifiez que terraform apply a réussi
terraform plan

# 2. Vérifiez les clés présentes
ls -la terraform/keys/

# 3. Si les clés ne sont pas là, regénérez-les
terraform apply -auto-approve

# 4. Relancez Ansible
cd ansible && ./deploy.sh
```

### Erreur : `UNREACHABLE! ... Permission denied (publickey)`

**Cause :** Ansible ne peut pas se connecter via SSH.

**Solutions :**

1. Vérifiez que les clés SSH existent et ont les bonnes permissions :
   ```bash
   ls -la terraform/keys/
   # Les permissions doivent être 400 ou 600
   ```

2. Vérifiez que les instances sont en cours d'exécution :
   ```bash
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]'
   ```

3. Vérifiez que les Security Groups autorisent SSH (port 22) :
   ```bash
   aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,IpPermissions[?FromPort==`22`]]'
   ```

### Erreur : `Certaines instances ne répondent pas`

**Cause :** Les instances mettent du temps à démarrer ou les Security Groups bloquent SSH.

**Solutions :**

```bash
# Attendez 30-60 secondes puis réessayez
sleep 60

# Tentez une connexion directe
ssh -i terraform/keys/votre-clé.pem admin@<IP-publique>

# Si ça marche, relancez Ansible
cd ansible && ./deploy.sh
```

### Conflit de ressources existantes

Si vous avez déjà créé des ressources sans préfixe et qu'elles entrent en conflit :

**Option 1 : Supprimer via AWS Console**

1. Allez sur [AWS Console - EC2](https://console.aws.amazon.com/ec2/)
2. Load Balancers → Supprimez les ALB en conflit
3. Target Groups → Supprimez les Target Groups en conflit
4. Relancez `terraform apply`

**Option 2 : Importer dans Terraform (avancé)**

```bash
# Importer l'ALB existant
terraform import module.france_prod.module.alb.aws_lb.main <arn-du-alb>

# Relancez terraform plan pour vérifier
terraform plan
```

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez ce guide
2. Consultez les logs de déploiement
3. Contactez le responsable de l'infrastructure

## 🏗️ Architecture

```
terraform/
├── main.tf                          # Configuration principale
├── variables.tf                     # Définition des variables
├── terraform.tfvars                 # ⭐ VOS PARAMÈTRES (local, ne pas committer)
├── terraform.tfvars.example         # Exemple de configuration
├── ansible-inventory.tpl            # Template Ansible inventory
├── set-aws-credentials.sh          # Script de chargement des credentials
├── keys/                            # ⭐ Clés SSH (ne pas committer, auto-générées)
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── database/
│   ├── ec2-instance/
│   └── environments/
│       ├── france/prod/
│       └── germany/prod/
└── ansible/
    ├── deploy.sh
    ├── site.yml
    ├── group_vars/
    ├── roles/
    └── inventory/
        └── hosts.yml               # ⭐ GÉNÉRÉ AUTOMATIQUEMENT par Terraform
```

## 📋 Checklist Avant de Commencer

- [ ] `terraform.tfvars` créé et configuré avec votre `personal_prefix`
- [ ] Credentials AWS chargés (`source ./set-aws-credentials.sh`)
- [ ] `terraform init` exécuté
- [ ] `terraform plan` vérifié (aucune suppression de ressources d'autres)
- [ ] Prêt à lancer `terraform apply`

