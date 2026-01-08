# Ansible Configuration for Medusa Deployment

This Ansible configuration deploys Medusa e-commerce platform across multiple regions (France and Germany) with support for dev, staging, and production environments.

## Structure

```
ansible/
├── site.yml                    # Main playbook
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── hosts.yml              # Inventory file (populated by Terraform)
├── group_vars/
│   ├── all.yml                # Common variables
│   ├── france.yml             # France-specific variables
│   └── germany.yml            # Germany-specific variables
└── roles/
    ├── system/                # System configuration
    ├── docker/                # Docker installation
    ├── nodejs/                # Node.js via NVM
    ├── nginx/                 # Nginx reverse proxy
    └── medusa/                # Medusa deployment
```

## Roles

### 1. System Role
- Updates apt cache
- Installs essential system packages
- Configures timezone

### 2. Docker Role
- Installs Docker CE
- Installs Docker Compose
- Configures Docker service
- Adds user to docker group

### 3. Node.js Role
- Installs NVM (Node Version Manager)
- Installs Node.js LTS
- Configures shell environment

### 4. Nginx Role
- Installs and configures Nginx
- Sets up reverse proxy for Medusa
- Configures backend and storefront routing

### 5. Medusa Role
- Manages Git repository
- Configures environment variables
- Deploys backend with Docker
- Deploys storefront
- Runs migrations
- Creates admin user (optional)

## Usage

### Prerequisites

1. Install Ansible:
```bash
pip install ansible
```

2. Install required collections:
```bash
ansible-galaxy collection install community.general
```

### Running the Playbook

Deploy to all hosts:
```bash
ansible-playbook site.yml
```

Deploy to specific environment:
```bash
ansible-playbook site.yml --limit france_dev
ansible-playbook site.yml --limit germany_prod
```

Deploy to specific region:
```bash
ansible-playbook site.yml --limit france
ansible-playbook site.yml --limit germany
```

Run specific roles with tags:
```bash
ansible-playbook site.yml --tags setup
ansible-playbook site.yml --tags medusa
ansible-playbook site.yml --tags nginx
```

### Configuration

#### Environment Variables

Set these environment variables before running:

```bash
# Security
export MEDUSA_JWT_SECRET="your-jwt-secret"
export MEDUSA_COOKIE_SECRET="your-cookie-secret"

# France Database
export FRANCE_DATABASE_URL="postgres://user:pass@host:5432/medusa_france"
export FRANCE_REDIS_URL="redis://host:6379"

# Germany Database
export GERMANY_DATABASE_URL="postgres://user:pass@host:5432/medusa_germany"
export GERMANY_REDIS_URL="redis://host:6379"
```

#### Inventory

Update [inventory/hosts.yml](inventory/hosts.yml) with your server IPs:

```yaml
france_dev:
  hosts:
    medusa-france-dev-1:
      ansible_host: 1.2.3.4
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/your-key.pem
```

#### Variables

Customize variables in:
- `group_vars/all.yml` - Common settings
- `group_vars/france.yml` - France region settings
- `group_vars/germany.yml` - Germany region settings
- `roles/*/defaults/main.yml` - Role-specific defaults

## Region Configuration

### France (Primary Region)
- AWS Region: eu-west-3 (Paris)
- Primary database replica
- `is_primary_region: true`

### Germany (Replica Region)
- AWS Region: eu-central-1 (Frankfurt)
- Secondary database replica
- `is_primary_region: false`

## Tags

- `system` - System configuration
- `docker` - Docker installation
- `nodejs` - Node.js installation
- `nginx` - Nginx configuration
- `medusa` - Medusa deployment
- `setup` - All setup roles (system, docker, nodejs)
- `application` - Application deployment
- `webserver` - Web server configuration

## Security Notes

1. Never commit secrets to version control
2. Use environment variables or Ansible Vault for sensitive data
3. Change default JWT and cookie secrets
4. Configure proper firewall rules
5. Use SSL/TLS certificates in production

## Troubleshooting

Check service status:
```bash
ansible all -m shell -a "systemctl status nginx"
ansible all -m shell -a "docker-compose ps" -b
```

View logs:
```bash
ansible all -m shell -a "journalctl -u nginx -n 50"
ansible all -m shell -a "docker-compose logs backend" -b
```

## Integration with Terraform

This Ansible configuration is designed to work with Terraform. Terraform should:
1. Provision EC2 instances
2. Generate inventory file dynamically
3. Trigger Ansible playbook after provisioning

Example Terraform output:
```hcl
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tpl", {
    france_dev_hosts = module.france_dev.instance_ips
    germany_dev_hosts = module.germany_dev.instance_ips
  })
  filename = "${path.module}/ansible/inventory/hosts.yml"
}
```
