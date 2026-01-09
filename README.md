# Medusa IAC Pipeline

## Quick Start

```bash
# Clone
git clone <repository-url>
cd Medusa-IAC-Pipeline

# Export AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-west-2"

# Terraform
cd terraform
terraform init
terraform plan
terraform apply

# Ansible
cd ansible
cp .env.example .env
# Edit .env with your configuration
./deploy.sh
```
