# Project Structure & File Reference

## Directory Layout

```
Terraform-Full-Project/
│
├── 📁 modules/                    # Reusable Terraform modules
│   ├── vpc/                       # VPC module
│   │   ├── main.tf               # VPC resources
│   │   ├── variables.tf           # Input variables
│   │   └── outputs.tf             # Output values
│   ├── security_group/            # Security groups module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/                       # EC2 instances module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                       # Application Load Balancer module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/                        # S3 buckets & state management
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── 📁 environments/               # Environment-specific configurations
│   ├── dev/                       # Development environment
│   │   ├── provider.tf            # AWS provider & backend config
│   │   ├── main.tf                # Main configuration
│   │   ├── variables.tf           # Variable definitions
│   │   ├── outputs.tf             # Output definitions
│   │   └── terraform.tfvars       # Environment variables
│   ├── prod/                      # Production environment
│   │   ├── provider.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── uat/                       # UAT environment
│       ├── provider.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── 📄 Jenkinsfile                 # Jenkins pipeline configuration
├── 📄 Makefile                    # Make targets for common commands
├── 📄 README.md                   # Main documentation
├── 📄 QUICKSTART.md               # Quick start guide
├── 📄 DEPLOYMENT.md               # Detailed deployment guide
├── 📄 BACKEND_SETUP.md            # Backend configuration guide
├── 📄 JENKINS_SETUP.md            # Jenkins pipeline setup
├── 📄 TROUBLESHOOTING.md          # Common issues & solutions
├── 📄 PROJECT_STRUCTURE.md        # This file
├── 📄 .gitignore                  # Git ignore patterns
├── 📄 .terraformignore            # Terraform ignore patterns
├── 🔧 setup_backend.sh            # Backend setup script
└── 🔧 tfctl.sh                    # Terraform control script
```

## File Descriptions

### Modules (`modules/`)

#### VPC Module (`modules/vpc/`)
- **Purpose:** Creates VPC with subnets, Internet Gateway, and NAT Gateway
- **Resources:**
  - AWS VPC
  - Public Subnets (2 per AZ)
  - Private Subnets (2 per AZ)
  - Internet Gateway
  - NAT Gateways with Elastic IPs
  - Route Tables (public & private)
  - Route Associations

#### Security Group Module (`modules/security_group/`)
- **Purpose:** Manages security groups for ALB and EC2
- **Resources:**
  - ALB Security Group (ports 80, 443)
  - EC2 Security Group (ports 22, 80, 443, 8080)

#### EC2 Module (`modules/ec2/`)
- **Purpose:** Creates EC2 instances with IAM roles
- **Resources:**
  - EC2 Instances (configurable count)
  - IAM Roles with policies
  - Instance Profiles
  - Launch Templates

#### ALB Module (`modules/alb/`)
- **Purpose:** Creates Application Load Balancer
- **Resources:**
  - Application Load Balancer
  - Target Group
  - Target Group Attachments
  - ALB Listener

#### S3 Module (`modules/s3/`)
- **Purpose:** Creates S3 buckets and state management infrastructure
- **Resources:**
  - Application S3 Bucket
  - Terraform State S3 Bucket
  - S3 Bucket Versioning
  - S3 Encryption
  - S3 Public Access Blocks
  - DynamoDB Table for state locking

### Environments

#### Dev Environment (`environments/dev/`)
- **Configuration:** Development setup with minimal resources
- **Instance Type:** t3.micro (free tier eligible)
- **Instance Count:** 2
- **Files:**
  - `provider.tf`: AWS provider configuration
  - `main.tf`: Module instantiation
  - `variables.tf`: Variable definitions
  - `outputs.tf`: Output definitions
  - `terraform.tfvars`: Variable values

#### Prod Environment (`environments/prod/`)
- **Configuration:** Production setup with higher specifications
- **Instance Type:** t3.small
- **Instance Count:** 2
- **Additional Security:** Same configuration as dev

#### UAT Environment (`environments/uat/`)
- **Configuration:** UAT setup for testing
- **Instance Type:** t3.micro
- **Instance Count:** 2

### Root Level Files

#### Documentation Files
- **README.md**: Main project documentation with overview
- **QUICKSTART.md**: Quick start guide for new users
- **DEPLOYMENT.md**: Step-by-step deployment instructions
- **BACKEND_SETUP.md**: Guide for backend infrastructure setup
- **JENKINS_SETUP.md**: Jenkins pipeline configuration guide
- **TROUBLESHOOTING.md**: Common issues and solutions
- **PROJECT_STRUCTURE.md**: This file - project organization

#### Configuration Files
- **.gitignore**: Git ignore patterns
- **.terraformignore**: Terraform ignore patterns
- **Makefile**: Make targets for common operations
- **Jenkinsfile**: Jenkins pipeline definition

#### Scripts
- **setup_backend.sh**: Automated backend infrastructure setup
- **tfctl.sh**: Multi-environment Terraform control script

## Key Features

### 📦 Modular Design
- Reusable modules for each AWS service
- Environment-specific configurations
- Easy to extend and maintain

### 🔐 Security
- Encrypted S3 buckets
- Private subnets with NAT
- IAM roles with least privilege
- Security groups with restricted access

### 🔄 State Management
- Remote S3 backend
- DynamoDB state locking
- Versioning enabled
- Encryption enabled

### 🚀 CI/CD Ready
- Jenkins pipeline included
- Automated validation
- Code formatting checks
- Approval gates for production

### 📊 Environment Isolation
- Separate configurations per environment
- Different resource sizes per environment
- Independent state files
- Easy to manage

## Usage Patterns

### Deploy Single Environment
```bash
cd environments/dev
terraform init
terraform apply -var-file="terraform.tfvars"
```

### Deploy All Environments
```bash
# Using Makefile
make init-all
make plan-all
make apply-all

# Using control script
./tfctl.sh init all
./tfctl.sh plan all
./tfctl.sh apply all
```

### Manage Specific Resources
```bash
# Plan only EC2 module
terraform plan -target=module.ec2

# Apply only VPC module
terraform apply -target=module.vpc

# Destroy only ALB
terraform destroy -target=module.alb
```

### Scale Infrastructure
```bash
# Edit environment variables
vim environments/dev/terraform.tfvars
# Change: instance_count = 4

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

## Adding New Environments

To add a new environment (e.g., staging):

1. Create new directory:
   ```bash
   mkdir environments/staging
   ```

2. Copy files from existing environment:
   ```bash
   cp environments/dev/* environments/staging/
   ```

3. Update variables in `staging/terraform.tfvars`:
   ```hcl
   environment = "staging"
   vpc_cidr = "10.3.0.0/16"
   ```

4. Update backend bucket in `staging/provider.tf`:
   ```hcl
   bucket = "terraform-state-staging-ACCOUNT_ID"
   ```

5. Initialize and deploy:
   ```bash
   cd environments/staging
   terraform init
   terraform apply -var-file="terraform.tfvars"
   ```

## Best Practices Implemented

✅ **DRY Principle:** Modules avoid code duplication
✅ **Separation of Concerns:** Clear module boundaries
✅ **Scalability:** Easy to add environments and resources
✅ **Maintainability:** Well-organized and documented
✅ **Security:** Encryption, access controls, IAM roles
✅ **Automation:** Scripts and pipelines for common tasks
✅ **Version Control:** Ready for Git with proper .gitignore

## Getting Started

1. **Read** [QUICKSTART.md](QUICKSTART.md) for quick setup
2. **Setup** backend with [setup_backend.sh](setup_backend.sh)
3. **Deploy** using Makefile: `make init ENVIRONMENT=dev`
4. **Manage** with [tfctl.sh](tfctl.sh) or Makefile
5. **Monitor** infrastructure in AWS console
6. **Document** any changes in code

## Support Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## Version Information

- **Terraform Version:** >= 1.0
- **AWS Provider:** ~> 5.0
- **Project Version:** 1.0.0
- **Last Updated:** April 28, 2026

---

For more information, see the main [README.md](README.md).
