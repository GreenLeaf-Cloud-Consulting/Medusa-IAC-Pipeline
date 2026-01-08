# Migration Guide - Ancien Playbook vers Nouvelle Structure

## Changements Principaux

### Avant (Monolithique)
```
ansible/
├── playbook.yml           # Un seul fichier avec toutes les tâches
├── vars.yml              # Variables minimales
└── inventory/
    └── main.txt
```

### Après (Modulaire avec Roles)
```
ansible/
├── site.yml                    # Playbook principal orchestrateur
├── ansible.cfg                 # Configuration Ansible
├── inventory/
│   └── hosts.yml              # Inventaire structuré par région
├── group_vars/
│   ├── all.yml                # Variables communes
│   ├── france.yml             # Variables France
│   └── germany.yml            # Variables Allemagne
└── roles/
    ├── system/                # Configuration système
    ├── docker/                # Installation Docker
    ├── nodejs/                # Installation Node.js
    ├── nginx/                 # Configuration Nginx
    └── medusa/                # Déploiement Medusa
```

## Avantages de la Nouvelle Structure

### 1. Principe de Responsabilité Unique
Chaque rôle a une responsabilité claire:
- **system**: Configuration système de base
- **docker**: Gestion Docker et Docker Compose
- **nodejs**: Installation et configuration Node.js/NVM
- **nginx**: Reverse proxy et configuration web
- **medusa**: Déploiement spécifique de l'application Medusa

### 2. Réutilisabilité
Les rôles peuvent être réutilisés dans d'autres projets:
```bash
# Utiliser uniquement le rôle Docker
ansible-playbook site.yml --tags docker

# Utiliser uniquement le rôle Nginx
ansible-playbook site.yml --tags nginx
```

### 3. Maintenabilité
- Code mieux organisé et plus facile à lire
- Variables centralisées par groupe/région
- Templates séparés pour chaque configuration
- Handlers pour gérer les redémarrages de services

### 4. Adaptabilité Multi-Région
Variables spécifiques par région:
- France: `is_primary_region: true`
- Germany: `is_primary_region: false`

### 5. Gestion des Secrets Améliorée
- Variables d'environnement pour les secrets
- Support d'Ansible Vault
- Fichier `.env.example` pour la documentation

## Mapping des Fonctionnalités

### Ancien Playbook → Nouveaux Rôles

| Tâches de l'ancien playbook | Nouveau rôle | Fichier |
|------------------------------|--------------|---------|
| Update apt cache | system | roles/system/tasks/main.yml |
| Install Nginx | nginx | roles/nginx/tasks/main.yml |
| Install Docker | docker | roles/docker/tasks/main.yml |
| Install Docker Compose | docker | roles/docker/tasks/main.yml |
| Install NVM/Node.js | nodejs | roles/nodejs/tasks/main.yml |
| SSH key generation | medusa | roles/medusa/tasks/git.yml |
| Clone Git repository | medusa | roles/medusa/tasks/git.yml |
| Configure .env | medusa | roles/medusa/tasks/environment.yml |
| Start Docker containers | medusa | roles/medusa/tasks/backend.yml |
| Deploy frontend | medusa | roles/medusa/tasks/storefront.yml |

## Différences Importantes

### 1. Configuration Git
**Avant:**
- Ajout automatique de la clé SSH à GitHub via API
- Clonage du repo `vitolinho/dev-ops`

**Après:**
- Génération de clé SSH (affichage manuel pour ajout)
- Configuration flexible du repository via variable `medusa_git_repo`
- Pas d'appel API automatique (plus sécurisé)

### 2. Variables d'Environnement
**Avant:**
```yaml
# Hardcodé dans le playbook
PRIMARY_REPLICA={% if 'france' in inventory_hostname %}1{% else %}0{% endif %}
```

**Après:**
```yaml
# Template Jinja2 propre
{% if is_primary_region | default(false) %}
PRIMARY_REPLICA=1
{% else %}
PRIMARY_REPLICA=0
{% endif %}
```

### 3. Déploiement Frontend
**Avant:**
- Démarrage en arrière-plan avec `nohup`

**Après:**
- Service systemd pour une meilleure gestion
- Fichier de service: `medusa-storefront.service`
- Gestion des logs via journald

### 4. Nginx
**Avant:**
- Seulement installation

**Après:**
- Configuration complète du reverse proxy
- Templates pour backend/storefront/admin
- Health check endpoint

## Guide de Migration

### Étape 1: Mettre à Jour l'Inventaire
Remplacer `inventory/main.txt` par `inventory/hosts.yml`:

```yaml
france_dev:
  hosts:
    server1:
      ansible_host: IP_ADDRESS
      ansible_user: ubuntu
```

### Étape 2: Configurer les Variables
1. Copier `.env.example` vers `.env`
2. Remplir les valeurs appropriées
3. Mettre à jour `group_vars/` si nécessaire

### Étape 3: Adapter le Repository Git
Dans `group_vars/all.yml`:
```yaml
medusa_git_repo: "https://github.com/your-org/your-medusa-repo.git"
medusa_git_branch: "main"
```

### Étape 4: Exécuter le Nouveau Playbook
```bash
# Test avec check mode
ansible-playbook site.yml --check

# Exécution réelle
ansible-playbook site.yml

# Par environnement
ansible-playbook site.yml --limit france_dev
```

## Variables Importantes à Configurer

### Sécurité (OBLIGATOIRE)
```bash
export MEDUSA_JWT_SECRET="your-secret"
export MEDUSA_COOKIE_SECRET="your-secret"
```

### Base de Données
```bash
export FRANCE_DATABASE_URL="postgres://..."
export GERMANY_DATABASE_URL="postgres://..."
```

### Redis
```bash
export FRANCE_REDIS_URL="redis://..."
export GERMANY_REDIS_URL="redis://..."
```

## Tests Recommandés

Après migration, vérifier:

1. **Services actifs**
```bash
ansible all -m shell -a "systemctl status nginx docker"
```

2. **Containers Docker**
```bash
ansible all -m shell -a "docker-compose ps" -b
```

3. **Node.js et NVM**
```bash
ansible all -m shell -a "source ~/.nvm/nvm.sh && node --version" -b
```

4. **Medusa Backend**
```bash
curl http://SERVER_IP:9000/health
```

## Rollback

Si nécessaire, les anciens fichiers sont sauvegardés:
- `playbook.yml.old`
- `vars.yml.old`

Pour restaurer:
```bash
mv playbook.yml.old playbook.yml
mv vars.yml.old vars.yml
```

## Support

Pour toute question sur la migration, consulter:
- [README.md](README.md) - Documentation complète
- [roles/*/defaults/main.yml] - Variables par défaut de chaque rôle
