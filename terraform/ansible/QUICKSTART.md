# Quick Start Guide - Ansible Medusa Deployment

## Installation Rapide

### 1. Installer Ansible
```bash
make install
```

ou manuellement :
```bash
pip install ansible
ansible-galaxy collection install community.general
```

### 2. Configurer les Variables d'Environnement
```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer et remplir les valeurs
nano .env

# Charger les variables
source .env
# ou
export $(cat .env | xargs)
```

### 3. Configurer l'Inventaire
Éditer [inventory/hosts.yml](inventory/hosts.yml) avec vos serveurs:

```yaml
france_dev:
  hosts:
    medusa-france-dev-1:
      ansible_host: 192.168.1.10
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/your-key.pem
```

### 4. Tester la Connexion
```bash
make ping
```

### 5. Déployer !
```bash
# Vérifier d'abord (dry-run)
make check

# Déployer sur tous les hosts
make deploy

# Ou déployer par environnement
make deploy-dev        # Dev uniquement
make deploy-staging    # Staging uniquement
make deploy-prod       # Production uniquement

# Ou par région
make deploy-france     # France uniquement
make deploy-germany    # Germany uniquement
```

## Commandes Utiles

### Déploiement Partiel
```bash
# Uniquement la configuration système
make setup-only

# Uniquement Medusa
make medusa-only

# Uniquement Nginx
make nginx-only
```

### Monitoring
```bash
# Vérifier le status des services
make status

# Voir les logs Nginx
make logs

# Voir les logs Medusa
make logs-medusa
```

### Gestion des Services
```bash
# Redémarrer Nginx
make restart-nginx

# Redémarrer Medusa
make restart-medusa
```

### Validation
```bash
# Valider l'inventaire
make validate-inventory

# Voir la structure de l'inventaire
make graph

# Vérifier les variables d'environnement
make verify-env
```

## Structure des Fichiers

```
ansible/
├── site.yml                           # Playbook principal
├── ansible.cfg                        # Configuration Ansible
├── Makefile                          # Commandes Make
├── README.md                         # Documentation complète
├── QUICKSTART.md                     # Ce fichier
├── MIGRATION.md                      # Guide de migration
├── .env.example                      # Exemple variables d'env
├── .gitignore                        # Fichiers à ignorer
│
├── inventory/
│   └── hosts.yml                     # Inventaire des serveurs
│
├── group_vars/
│   ├── all.yml                       # Variables globales
│   ├── france.yml                    # Variables France
│   └── germany.yml                   # Variables Germany
│
└── roles/
    ├── system/                       # Config système
    │   ├── tasks/main.yml
    │   └── defaults/main.yml
    │
    ├── docker/                       # Docker + Compose
    │   ├── tasks/main.yml
    │   └── defaults/main.yml
    │
    ├── nodejs/                       # Node.js via NVM
    │   ├── tasks/main.yml
    │   └── defaults/main.yml
    │
    ├── nginx/                        # Reverse proxy
    │   ├── tasks/main.yml
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   └── templates/medusa.conf.j2
    │
    └── medusa/                       # Application Medusa
        ├── tasks/
        │   ├── main.yml
        │   ├── git.yml
        │   ├── environment.yml
        │   ├── backend.yml
        │   └── storefront.yml
        ├── defaults/main.yml
        ├── handlers/main.yml
        └── templates/
            ├── medusa.env.j2
            └── medusa-storefront.service.j2
```

## Variables Importantes

### Variables Requises
Ces variables DOIVENT être définies:

```bash
# Sécurité
export MEDUSA_JWT_SECRET="your-super-secret-jwt-key"
export MEDUSA_COOKIE_SECRET="your-super-secret-cookie-key"

# Base de données
export FRANCE_DATABASE_URL="postgres://user:pass@host/db"
export GERMANY_DATABASE_URL="postgres://user:pass@host/db"

# Redis
export FRANCE_REDIS_URL="redis://host:6379"
export GERMANY_REDIS_URL="redis://host:6379"
```

### Variables Optionnelles
Peuvent être surchargées dans `group_vars/`:

- `medusa_git_repo`: Repository Git de Medusa
- `medusa_git_branch`: Branche à déployer
- `medusa_backend_port`: Port du backend (défaut: 9000)
- `medusa_storefront_port`: Port du storefront (défaut: 8000)
- `nodejs_version`: Version de Node.js (défaut: --lts)
- `docker_compose_version`: Version de Docker Compose

## Tags Disponibles

Vous pouvez cibler des parties spécifiques du déploiement:

```bash
# Par composant
ansible-playbook site.yml --tags system
ansible-playbook site.yml --tags docker
ansible-playbook site.yml --tags nodejs
ansible-playbook site.yml --tags nginx
ansible-playbook site.yml --tags medusa

# Par type
ansible-playbook site.yml --tags setup        # system + docker + nodejs
ansible-playbook site.yml --tags application  # medusa
ansible-playbook site.yml --tags webserver    # nginx
```

## Exemples de Scénarios

### Scénario 1: Premier Déploiement
```bash
# 1. Configuration
cp .env.example .env
nano .env
nano inventory/hosts.yml

# 2. Vérification
make verify-env
make ping

# 3. Déploiement
make check          # Dry-run
make deploy-dev     # Déployer en dev d'abord
```

### Scénario 2: Mise à Jour de l'Application
```bash
# Uniquement le rôle Medusa
make medusa-only

# Ou avec tags
ansible-playbook site.yml --tags medusa --limit france_prod
```

### Scénario 3: Reconfiguration Nginx
```bash
# 1. Modifier le template
nano roles/nginx/templates/medusa.conf.j2

# 2. Appliquer
make nginx-only
```

### Scénario 4: Debugging
```bash
# Vérifier les services
make status

# Voir les logs
make logs
make logs-medusa

# Connexion SSH directe
ansible france_dev -m shell -a "docker-compose ps" -b
```

## Résolution de Problèmes

### Problème: Échec de connexion SSH
```bash
# Vérifier la connectivité
ansible all -m ping

# Tester SSH manuellement
ssh -i ~/.ssh/your-key.pem ubuntu@SERVER_IP
```

### Problème: Docker Compose ne démarre pas
```bash
# Vérifier les logs
ansible all -m shell -a "cd ~/medusa && docker-compose logs" -b

# Vérifier le fichier .env
ansible all -m shell -a "cat ~/medusa/.env" -b
```

### Problème: Variables d'environnement manquantes
```bash
# Vérifier
make verify-env

# Charger depuis .env
export $(cat .env | xargs)
```

## Support

Pour plus d'informations:
- Documentation complète: [README.md](README.md)
- Guide de migration: [MIGRATION.md](MIGRATION.md)
- Defaults de chaque rôle: `roles/*/defaults/main.yml`

## Commandes Make Disponibles

Exécutez `make help` pour voir toutes les commandes disponibles:

```bash
make help
```

Sortie attendue:
```
Available targets:
  check                 Run playbook in check mode (dry-run)
  clean                 Clean temporary files
  deploy                Deploy to all hosts
  deploy-dev            Deploy to dev environments
  deploy-france         Deploy to France region only
  deploy-germany        Deploy to Germany region only
  deploy-prod           Deploy to production environments
  deploy-staging        Deploy to staging environments
  graph                 Show inventory graph
  help                  Show this help message
  install               Install Ansible and required collections
  logs                  Show logs from all hosts
  logs-medusa           Show Medusa backend logs
  medusa-only           Deploy only Medusa application
  nginx-only            Configure Nginx only
  ping                  Ping all hosts
  restart-medusa        Restart Medusa backend on all hosts
  restart-nginx         Restart Nginx on all hosts
  setup-only            Run only setup roles (system, docker, nodejs)
  status                Check services status on all hosts
  validate-inventory    Validate inventory file
  verify-env            Verify environment variables are set
```
