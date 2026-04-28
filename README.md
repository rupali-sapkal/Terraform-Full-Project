# Terraform Full Project - Setup & Configuration Guide

## Project Overview

This Terraform project sets up a complete AWS infrastructure across three environments (dev, prod, uat) with the following components:

### Infrastructure Components
- **VPC** - Virtual Private Cloud with public and private subnets
- **Subnets** - 2 public and 2 private subnets per environment
- **Internet Gateway (IGW)** - For public internet access
- **NAT Gateway** - For private subnet internet access
- **Route Tables** - Public and private route configurations
- **Security Groups** - ALB and EC2 security groups
- **EC2 Instances** - 2 instances per environment (configurable)
- **Application Load Balancer (ALB)** - Distributes traffic across EC2 instances
- **S3 Buckets** - Application bucket and Terraform state bucket
- **DynamoDB** - For Terraform state locking

## Project Structure

```
Terraform-Full-Project/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security_group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── provider.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── prod/
│   │   ├── provider.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── uat/
│       ├── provider.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── Jenkinsfile
└── README.md
```

## Environment Specifications

### Dev Environment
- **VPC CIDR:** 10.0.0.0/16
- **Public Subnets:** 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets:** 10.0.10.0/24, 10.0.11.0/24
- **Instance Type:** t3.micro
- **Instance Count:** 2

### Prod Environment
- **VPC CIDR:** 10.1.0.0/16
- **Public Subnets:** 10.1.1.0/24, 10.1.2.0/24
- **Private Subnets:** 10.1.10.0/24, 10.1.11.0/24
- **Instance Type:** t3.small
- **Instance Count:** 2

### UAT Environment
- **VPC CIDR:** 10.2.0.0/16
- **Public Subnets:** 10.2.1.0/24, 10.2.2.0/24
- **Private Subnets:** 10.2.10.0/24, 10.2.11.0/24
- **Instance Type:** t3.micro
- **Instance Count:** 2

## Prerequisites

1. **AWS Account** - Valid AWS account with appropriate permissions
2. **Terraform** - Version 1.0 or higher
3. **AWS CLI** - Configured with appropriate credentials
4. **Jenkins** - For CI/CD pipeline (optional)
5. **Git** - For version control

### AWS Permissions Required
- EC2 (CreateInstance, DescribeInstances, etc.)
- VPC (CreateVPC, CreateSubnet, etc.)
- S3 (CreateBucket, PutBucketVersioning, etc.)
- IAM (CreateRole, PutRolePolicy, etc.)
- DynamoDB (CreateTable)
- ElasticLoadBalancing (CreateLoadBalancer)

## Setup Instructions

### Step 1: Initialize AWS Backend

First, create S3 bucket and DynamoDB table for storing Terraform state:

```bash
# Set your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 buckets manually or use the setup script
aws s3 mb s3://terraform-state-dev-${AWS_ACCOUNT_ID} --region us-east-1
aws s3 mb s3://terraform-state-prod-${AWS_ACCOUNT_ID} --region us-east-1
aws s3 mb s3://terraform-state-uat-${AWS_ACCOUNT_ID} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket terraform-state-dev-${AWS_ACCOUNT_ID} --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket terraform-state-prod-${AWS_ACCOUNT_ID} --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket terraform-state-uat-${AWS_ACCOUNT_ID} --versioning-configuration Status=Enabled
```

### Step 2: Update Backend Configuration

Update the backend configuration in `provider.tf` for each environment:

```bash
# For dev
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" environments/dev/provider.tf

# For prod
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" environments/prod/provider.tf

# For uat
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" environments/uat/provider.tf
```

### Step 3: Initialize Terraform

```bash
# For dev
cd environments/dev
terraform init

# For prod
cd ../prod
terraform init

# For uat
cd ../uat
terraform init
```

### Step 4: Plan Infrastructure

```bash
cd environments/dev
terraform plan -var-file="terraform.tfvars"
```

### Step 5: Apply Configuration

```bash
cd environments/dev
terraform apply -var-file="terraform.tfvars"
```

## Terraform Commands

### Common Commands

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Destroy resources
terraform destroy -var-file="terraform.tfvars"

# Show outputs
terraform output

# Show specific state
terraform state show
```

### Environment-Specific Commands

```bash
# Deploy to Dev
cd environments/dev && terraform apply -var-file="terraform.tfvars"

# Deploy to Prod
cd ../prod && terraform apply -var-file="terraform.tfvars"

# Deploy to UAT
cd ../uat && terraform apply -var-file="terraform.tfvars"
```

## Jenkins Pipeline

The `Jenkinsfile` provides a complete CI/CD pipeline for infrastructure deployment.

### Pipeline Parameters
- **ENVIRONMENT:** Select between dev, prod, or uat
- **ACTION:** Choose between plan, apply, or destroy
- **AUTO_APPROVE:** Auto-approve changes (use carefully)

### Pipeline Stages
1. **Checkout** - Clone repository
2. **Terraform Init** - Initialize Terraform
3. **Terraform Validate** - Validate configuration
4. **Terraform Format Check** - Check code formatting
5. **TFLint** - Lint Terraform code
6. **Terraform Plan** - Create execution plan
7. **Approval** - Manual approval (for apply)
8. **Terraform Apply** - Apply changes
9. **Terraform Output** - Display outputs

### Running Jenkins Pipeline

1. Create a new Pipeline job in Jenkins
2. Point to this repository
3. Configure pipeline to use Jenkinsfile
4. Run with desired parameters
5. Approve changes when prompted

## State Management

### Terraform State Storage
- **Location:** S3 bucket (`terraform-state-{environment}-{account-id}`)
- **Encryption:** AES256 (enabled)
- **Versioning:** Enabled for rollback capability
- **Locking:** DynamoDB table for concurrent access protection

### State Backend Configuration
```hcl
backend "s3" {
  bucket         = "terraform-state-dev-ACCOUNT_ID"
  key            = "dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks-dev"
}
```

## Security Considerations

1. **Sensitive Data:** Use AWS Secrets Manager or Parameter Store
2. **IAM Roles:** Principle of least privilege
3. **Security Groups:** Restrict ingress/egress rules
4. **S3 Buckets:** Block public access
5. **State File:** Encrypted and versioned
6. **Network:** Private subnets for database tier

## Outputs

After applying Terraform, you'll get:
- **VPC ID** - Main VPC identifier
- **ALB DNS Name** - Load balancer endpoint
- **EC2 Instance IDs** - Instance identifiers
- **EC2 Public IPs** - Instance public IP addresses
- **S3 Bucket Names** - Application and state buckets

## Cost Estimation

Using AWS Pricing Calculator:
- **Dev:** ~$50-80/month (t3.micro instances)
- **Prod:** ~$80-120/month (t3.small instances)
- **UAT:** ~$50-80/month (t3.micro instances)
- **Storage:** ~$1-5/month for S3

*Prices vary by region and AWS pricing changes*

## Troubleshooting

### Common Issues

1. **State Lock Error**
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

2. **VPC CIDR Conflicts**
   - Update CIDR blocks in terraform.tfvars
   - Ensure no overlapping CIDR ranges

3. **IAM Permission Errors**
   - Verify AWS credentials
   - Check IAM policies attached to user/role

4. **Module Not Found**
   ```bash
   terraform init -upgrade
   ```

## Best Practices

1. **Version Control** - Use Git for all configurations
2. **Code Review** - Implement peer review process
3. **Testing** - Use terraform plan before apply
4. **Documentation** - Keep README updated
5. **Monitoring** - Enable CloudWatch metrics
6. **Backup** - Regular backups of state files
7. **Access Control** - Restrict state file access

## Support & Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc)

## License

This project is open source and available under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Contact

For questions or issues, please contact the DevOps team.
