# Terraform Project - Infrastructure as Code

This comprehensive Terraform project provides production-ready infrastructure for AWS with three fully configured environments (dev, prod, uat).

## 📋 Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd Terraform-Full-Project

# 2. Setup backend
chmod +x setup_backend.sh
./setup_backend.sh

# 3. Update Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "s/ACCOUNT_ID/${ACCOUNT_ID}/g" environments/*/provider.tf

# 4. Initialize and deploy
cd environments/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## 📦 What's Included

✅ **3 Complete Environments** - Dev, Prod, UAT
✅ **VPC with Subnets** - Public & Private subnets with proper routing
✅ **2 EC2 Instances** - Per environment with IAM roles
✅ **Application Load Balancer** - Distributes traffic across instances
✅ **S3 Buckets** - Application storage and state management
✅ **Security Groups** - Pre-configured for ALB and EC2
✅ **Internet Gateway & NAT** - Internet connectivity
✅ **Terraform State** - Remote S3 backend with DynamoDB locking
✅ **Jenkins Pipeline** - Full CI/CD automation
✅ **Documentation** - Complete setup guides

## 📚 Documentation

- [README.md](README.md) - Main project documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [BACKEND_SETUP.md](BACKEND_SETUP.md) - Backend configuration
- [JENKINS_SETUP.md](JENKINS_SETUP.md) - Jenkins pipeline setup

## 🚀 Usage

### Using Makefile

```bash
# Plan changes
make plan ENVIRONMENT=dev

# Apply changes
make apply ENVIRONMENT=dev

# All environments
make plan-all
make apply-all
```

### Using Terraform CLI

```bash
cd environments/dev

# Initialize
terraform init

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"

# Destroy
terraform destroy -var-file="terraform.tfvars"
```

### Using Control Script

```bash
chmod +x tfctl.sh

# Plan
./tfctl.sh plan dev

# Apply
./tfctl.sh apply prod

# All environments
./tfctl.sh init all
./tfctl.sh plan all
```

## 🏗️ Infrastructure Specifications

### Development
- **VPC CIDR:** 10.0.0.0/16
- **Instance Type:** t3.micro (free tier)
- **Instance Count:** 2
- **Cost:** ~$50-80/month

### Production
- **VPC CIDR:** 10.1.0.0/16
- **Instance Type:** t3.small
- **Instance Count:** 2
- **Cost:** ~$80-120/month

### UAT
- **VPC CIDR:** 10.2.0.0/16
- **Instance Type:** t3.micro
- **Instance Count:** 2
- **Cost:** ~$50-80/month

## 🔐 Security Features

✓ Encrypted S3 buckets
✓ VPC with private subnets
✓ Security groups with restricted access
✓ IAM roles for EC2 instances
✓ State file versioning
✓ DynamoDB state locking
✓ Public access blocks on S3

## 📊 Module Structure

```
modules/
├── vpc/              - VPC, Subnets, IGW, NAT
├── security_group/   - ALB and EC2 security groups
├── ec2/              - EC2 instances with IAM
├── alb/              - Application Load Balancer
└── s3/               - S3 buckets and state management
```

## 🔄 CI/CD Integration

The included Jenkinsfile provides:
- Automated planning
- Code linting (TFLint)
- Format validation
- Safe apply with approvals
- Destroy protection
- Real-time logging

## 🛠️ Requirements

- Terraform >= 1.0
- AWS CLI v2
- AWS Account with permissions
- Git (for version control)
- Jenkins (for CI/CD - optional)

## 📝 Environment Variables

```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
export TF_LOG="INFO"  # or DEBUG
```

## 🐛 Troubleshooting

Common issues and solutions:

```bash
# State lock issue
terraform force-unlock <LOCK_ID>

# Force re-initialization
terraform init -reconfigure

# Migrate state
terraform init -migrate-state

# Verify AWS credentials
aws sts get-caller-identity
```

## 📞 Support

For questions or issues:
1. Check the documentation files
2. Review Terraform logs
3. Consult AWS documentation
4. Contact the DevOps team

## 📄 License

This project is open source and available under the MIT License.

## 👥 Contributing

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` to format code
4. Submit a pull request
5. Await peer review and approval

---

**Last Updated:** April 28, 2026
**Maintained By:** DevOps Team
**Version:** 1.0.0
