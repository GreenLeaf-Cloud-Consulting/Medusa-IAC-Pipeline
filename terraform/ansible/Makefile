.PHONY: help install check deploy deploy-france deploy-germany deploy-dev deploy-staging deploy-prod ping status logs clean

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo '${GREEN}Available targets:${NC}'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2}'

install: ## Install Ansible and required collections
	@echo "${GREEN}Installing Ansible...${NC}"
	pip install ansible
	@echo "${GREEN}Installing required Ansible collections...${NC}"
	ansible-galaxy collection install community.general

check: ## Run playbook in check mode (dry-run)
	@echo "${GREEN}Running playbook in check mode...${NC}"
	ansible-playbook site.yml --check

deploy: ## Deploy to all hosts
	@echo "${GREEN}Deploying to all hosts...${NC}"
	ansible-playbook site.yml

deploy-france: ## Deploy to France region only
	@echo "${GREEN}Deploying to France region...${NC}"
	ansible-playbook site.yml --limit france

deploy-germany: ## Deploy to Germany region only
	@echo "${GREEN}Deploying to Germany region...${NC}"
	ansible-playbook site.yml --limit germany

deploy-dev: ## Deploy to dev environments
	@echo "${GREEN}Deploying to dev environments...${NC}"
	ansible-playbook site.yml --limit france_dev,germany_dev

deploy-staging: ## Deploy to staging environments
	@echo "${GREEN}Deploying to staging environments...${NC}"
	ansible-playbook site.yml --limit france_staging,germany_staging

deploy-prod: ## Deploy to production environments
	@echo "${GREEN}Deploying to production environments...${NC}"
	ansible-playbook site.yml --limit france_prod,germany_prod

setup-only: ## Run only setup roles (system, docker, nodejs)
	@echo "${GREEN}Running setup tasks only...${NC}"
	ansible-playbook site.yml --tags setup

medusa-only: ## Deploy only Medusa application
	@echo "${GREEN}Deploying Medusa application only...${NC}"
	ansible-playbook site.yml --tags medusa

nginx-only: ## Configure Nginx only
	@echo "${GREEN}Configuring Nginx only...${NC}"
	ansible-playbook site.yml --tags nginx

ping: ## Ping all hosts
	@echo "${GREEN}Pinging all hosts...${NC}"
	ansible all -m ping

status: ## Check services status on all hosts
	@echo "${GREEN}Checking services status...${NC}"
	@echo "\n${YELLOW}Nginx status:${NC}"
	ansible all -m shell -a "systemctl status nginx" -b || true
	@echo "\n${YELLOW}Docker status:${NC}"
	ansible all -m shell -a "systemctl status docker" -b || true
	@echo "\n${YELLOW}Docker containers:${NC}"
	ansible all -m shell -a "docker-compose ps" -b || true

logs: ## Show logs from all hosts
	@echo "${GREEN}Showing Nginx logs...${NC}"
	ansible all -m shell -a "journalctl -u nginx -n 50 --no-pager" -b

logs-medusa: ## Show Medusa backend logs
	@echo "${GREEN}Showing Medusa backend logs...${NC}"
	ansible all -m shell -a "cd ~/medusa && docker-compose logs --tail=50 backend" -b

restart-nginx: ## Restart Nginx on all hosts
	@echo "${GREEN}Restarting Nginx...${NC}"
	ansible all -m service -a "name=nginx state=restarted" -b

restart-medusa: ## Restart Medusa backend on all hosts
	@echo "${GREEN}Restarting Medusa backend...${NC}"
	ansible all -m shell -a "cd ~/medusa && docker-compose restart backend" -b

clean: ## Clean temporary files
	@echo "${GREEN}Cleaning temporary files...${NC}"
	find . -name "*.retry" -delete
	rm -rf /tmp/ansible_facts
	@echo "${GREEN}Done!${NC}"

validate-inventory: ## Validate inventory file
	@echo "${GREEN}Validating inventory...${NC}"
	ansible-inventory --list -i inventory/hosts.yml

graph: ## Show inventory graph
	@echo "${GREEN}Showing inventory graph...${NC}"
	ansible-inventory --graph -i inventory/hosts.yml

verify-env: ## Verify environment variables are set
	@echo "${GREEN}Verifying environment variables...${NC}"
	@test -n "$$MEDUSA_JWT_SECRET" || (echo "${YELLOW}Warning: MEDUSA_JWT_SECRET not set${NC}" && exit 1)
	@test -n "$$MEDUSA_COOKIE_SECRET" || (echo "${YELLOW}Warning: MEDUSA_COOKIE_SECRET not set${NC}" && exit 1)
	@echo "${GREEN}All required environment variables are set!${NC}"
