# Configuration des Credentials AWS

## Étapes simples

### 1. Créer le fichier .env

```bash
cd terraform
cp .env.example .env
```

### 2. Modifier .env avec vos credentials

Ouvrez `.env` et remplissez vos credentials AWS:

```bash
AWS_ACCESS_KEY_ID=votre_access_key_ici
AWS_SECRET_ACCESS_KEY=votre_secret_key_ici
AWS_DEFAULT_REGION=eu-west-2
```

### 3. Charger les credentials

```bash
source ./set-aws-credentials.sh
```

### 4. Vérifier

```bash
aws sts get-caller-identity
```

Si ça fonctionne, vous pouvez lancer Terraform!

## Important

- **Ne commitez JAMAIS le fichier .env** (déjà dans .gitignore)
- Le fichier `.env.example` est juste un template
- Les credentials sont valides uniquement pour la session shell actuelle
