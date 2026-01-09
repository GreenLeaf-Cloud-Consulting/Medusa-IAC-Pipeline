# Guide de Travail en Équipe

## Problème

Quand plusieurs membres de l'équipe travaillent avec les mêmes credentials AWS, les ressources entrent en conflit car elles portent les mêmes noms (ALB, Target Groups, Security Groups, etc.).

## Solution

Chaque membre de l'équipe utilise un **préfixe personnel** pour ses ressources. Toutes les ressources AWS créées par Terraform incluront votre préfixe personnel dans leur nom, garantissant qu'elles ne rentrent pas en conflit avec celles des autres membres.

## Configuration

### 1. Créer votre fichier de configuration

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Modifier le fichier terraform.tfvars

Ouvrez [terraform/terraform.tfvars](terraform/terraform.tfvars) et modifiez avec votre prénom :

```hcl
# Utilisez votre prénom ou initiales
personal_prefix = "votre-prenom"  # Exemple: "alice", "bob", "jd", etc.

# Environnement (gardez "dev" pour éviter les conflits)
environment = "dev"
```

**Important:**
- Utilisez uniquement des lettres minuscules, chiffres et tirets
- Pas d'espaces, pas de caractères spéciaux
- Exemples valides: `alice`, `bob`, `jd`, `marie-claire`, `thomas2`

### 3. Configurer les credentials AWS

Créez le fichier `.env` avec vos credentials:

```bash
cd terraform
cp .env.example .env
# Modifiez .env avec vos credentials AWS
```

Puis chargez-les:

```bash
source ./set-aws-credentials.sh
```

Voir [README_CREDENTIALS.md](terraform/README_CREDENTIALS.md) pour plus de détails.

### 4. Déployer votre infrastructure

```bash
# Initialiser Terraform (première fois uniquement)
terraform init

# Vérifier le plan
terraform plan

# Déployer
terraform apply
```

## Exemples de noms de ressources

Avec `personal_prefix = "jugurta"` et `environment = "dev"`, vos ressources s'appelleront :

- **ALB France:** `jugurta-dev-france-alb`
- **ALB Germany:** `jugurta-dev-germany-alb`
- **Target Group:** `jugurta-dev-france-medusa-tg`
- **Security Groups:** `jugurta-dev-france-alb-sg`
- **VPC France:** `jugurta-dev-france-vpc`
- **Instances App:** `jugurta-dev-app-1-app`, `jugurta-dev-app-2-app`
- **Database Primary:** `jugurta-dev-france-db-primary`

Avec `personal_prefix = "alice"`, ses ressources s'appelleront :

- **ALB France:** `alice-dev-france-alb`
- **ALB Germany:** `alice-dev-germany-alb`
- **Target Group:** `alice-dev-france-medusa-tg`
- etc.

## Structure des noms

```
{personal_prefix}-{environment}-{region}-{resource}

Exemples:
- jugurta-dev-france-alb
- alice-dev-germany-medusa-tg
- bob-prod-france-alb-sg
- marie-dev-france-vpc
```

## Nettoyage

Pour supprimer vos ressources :

```bash
source ./set-aws-credentials.sh
terraform destroy
```

**Note:** Ceci supprimera UNIQUEMENT vos ressources (celles avec votre préfixe). Les ressources des autres membres ne seront pas affectées.

## Important - Sécurité

### Ne commitez JAMAIS votre terraform.tfvars

Le fichier `terraform.tfvars` est déjà dans [.gitignore](terraform/.gitignore) pour éviter les commits accidentels. Ce fichier contient votre configuration personnelle et ne doit pas être partagé.

**Fichiers à ne jamais committer:**
- `terraform.tfvars` - Votre configuration personnelle
- `*.tfstate` - État de votre infrastructure
- `keys/` - Clés SSH générées
- `.terraform/` - Dépendances Terraform

### Fichiers à committer

- `terraform.tfvars.example` - Template de configuration
- Tous les fichiers `.tf` - Code Terraform
- `.gitignore` - Configuration Git
- Documentation

## Bonnes pratiques

### 1. Environnements

- **dev:** Utilisez cet environnement pour le développement et les tests
- **staging:** Pré-production (optionnel)
- **prod:** Production - Réservé au responsable d'équipe

### 2. Préfixes recommandés

- Utilisez votre **prénom** pour faciliter l'identification
- Si vous avez un prénom très long, utilisez vos **initiales**
- Soyez **cohérent** - ne changez pas votre préfixe

### 3. Coordination

- Chaque membre doit avoir son propre préfixe **unique**
- Communiquez votre préfixe à l'équipe pour éviter les doublons
- Documentez qui utilise quel préfixe

## En cas de conflit existant

Si vous avez déjà des ressources créées qui entrent en conflit :

### Option 1: Les supprimer manuellement (Recommandé)

```bash
# Via AWS Console:
# 1. Allez sur AWS Console > EC2 > Load Balancers
# 2. Supprimez les ALB en conflit
# 3. Allez sur EC2 > Target Groups
# 4. Supprimez les Target Groups en conflit
# 5. Vérifiez les Security Groups, VPCs, etc.
```

### Option 2: Les supprimer via Terraform (si vous avez le state)

```bash
cd terraform
terraform destroy
```

### Option 3: Les importer dans votre state (Avancé)

Si vous voulez conserver les ressources existantes et les gérer avec votre nouveau préfixe :

```bash
# Attention: Cette option est avancée et nécessite une bonne compréhension de Terraform
terraform import module.france_prod.module.alb.aws_lb.main <arn-du-alb>
```

## Dépannage

### Erreur: "ALB already exists"

```
Error: Error creating ALB: DuplicateLoadBalancerName
```

**Solution:** Quelqu'un d'autre utilise le même préfixe que vous, ou vous avez des ressources existantes.
1. Changez votre `personal_prefix` dans `terraform.tfvars`
2. Ou supprimez les ressources en conflit (voir section ci-dessus)

### Erreur: "Target Group already exists"

```
Error: Error creating LB Target Group: DuplicateTargetGroupName
```

**Solution:** Même cause que ci-dessus. Changez votre préfixe ou supprimez les ressources en conflit.

### Terraform ne trouve pas terraform.tfvars

```
Error: No value for required variable
```

**Solution:** Vous n'avez pas créé le fichier `terraform.tfvars`.
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Modifiez le fichier avec votre configuration
```

### Validation du préfixe échoue

```
Error: Invalid value for variable "personal_prefix"
```

**Solution:** Votre préfixe contient des caractères invalides. Utilisez uniquement:
- Lettres minuscules (a-z)
- Chiffres (0-9)
- Tirets (-)

## Aide supplémentaire

Si vous rencontrez des problèmes :

1. Vérifiez que vous avez bien copié et modifié `terraform.tfvars`
2. Vérifiez que votre préfixe est unique dans l'équipe
3. Consultez la [documentation Terraform](https://www.terraform.io/docs)
4. Demandez de l'aide à votre équipe

## Workflow recommandé

```bash
# 1. Créer vos fichiers de configuration (première fois uniquement)
cd terraform

# Configuration Terraform
cp terraform.tfvars.example terraform.tfvars
# Modifier terraform.tfvars avec votre préfixe

# Configuration AWS
cp .env.example .env
# Modifier .env avec vos credentials AWS

# 2. Charger les credentials AWS
source ./set-aws-credentials.sh

# 3. Initialiser Terraform (première fois uniquement)
terraform init

# 4. Vérifier les changements
terraform plan

# 5. Appliquer les changements
terraform apply

# 6. Travailler sur votre infrastructure...

# 7. Nettoyer quand vous avez terminé
terraform destroy
```

## Résumé

- Chaque membre utilise un **préfixe personnel unique**
- Le fichier `terraform.tfvars` n'est **jamais commité**
- Utilisez `environment = "dev"` pour le développement
- Communiquez votre préfixe à l'équipe
- Supprimez vos ressources avec `terraform destroy` quand vous avez fini
