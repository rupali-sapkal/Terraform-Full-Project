# Deployment Instructions

## Quick Start Guide

### Prerequisites
- Terraform >= 1.0
- AWS CLI configured
- AWS account with appropriate permissions
- S3 bucket and DynamoDB table for state management

## Step-by-Step Deployment

### 1. Setup Backend Infrastructure

```bash
# Run the backend setup script
chmod +x setup_backend.sh
./setup_backend.sh
```

This will create:
- S3 buckets for each environment
- DynamoDB tables for state locking

### 2. Update Backend Configuration

Replace `ACCOUNT_ID` in provider.tf files:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Update all environments
for env in dev prod uat; do
  sed -i "s/ACCOUNT_ID/${ACCOUNT_ID}/g" environments/${env}/provider.tf
done
```

### 3. Initialize Terraform

```bash
# For each environment
cd environments/dev
terraform init

cd ../prod
terraform init

cd ../uat
terraform init
```

### 4. Review Configuration

```bash
cd environments/dev
terraform plan -var-file="terraform.tfvars"
```

Review the output to understand what will be created.

### 5. Deploy Infrastructure

```bash
cd environments/dev
terraform apply -var-file="terraform.tfvars"
```

Type `yes` when prompted to confirm.

### 6. Verify Deployment

```bash
# View outputs
terraform output

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# Access ALB
ALB_DNS=$(terraform output alb_dns_name)
curl "http://${ALB_DNS}"
```

## Environment-Specific Deployments

### Deploy to Production

```bash
cd environments/prod
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Deploy to UAT

```bash
cd environments/uat
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Managing Infrastructure

### Update Configuration

1. Modify `terraform.tfvars` in the environment directory
2. Run `terraform plan` to see changes
3. Run `terraform apply` to apply changes

### Scale Instances

Update `instance_count` in `terraform.tfvars`:

```hcl
instance_count = 4  # Change from 2 to 4
```

Then run:

```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Add/Remove Resources

1. Modify module configuration in `main.tf`
2. Run `terraform plan`
3. Run `terraform apply`

## Cleanup

### Destroy Environment

```bash
cd environments/dev
terraform destroy -var-file="terraform.tfvars"
```

Type `yes` when prompted.

### Destroy All Environments

```bash
# Dev
cd environments/dev && terraform destroy -var-file="terraform.tfvars" -auto-approve

# Prod
cd ../prod && terraform destroy -var-file="terraform.tfvars" -auto-approve

# UAT
cd ../uat && terraform destroy -var-file="terraform.tfvars" -auto-approve
```

## Using Jenkins Pipeline

### Setup Jenkins (See JENKINS_SETUP.md)

### Run Pipeline

1. Open Jenkins and select `Terraform-Infrastructure-Pipeline`
2. Click **Build with Parameters**
3. Select:
   - Environment: dev/prod/uat
   - Action: plan/apply/destroy
   - Auto Approve: false (for safety)
4. Click **Build**
5. Monitor in build logs

## Accessing Resources

### EC2 Instances

```bash
# Get instance IPs
terraform output ec2_instance_public_ips

# SSH into instance
ssh -i /path/to/key.pem ec2-user@<PUBLIC_IP>
```

### Application Load Balancer

```bash
# Get ALB DNS
ALB_DNS=$(terraform output alb_dns_name)

# Access application
curl "http://${ALB_DNS}"
```

### S3 Bucket

```bash
# List bucket contents
aws s3 ls s3://$(terraform output app_bucket_name)

# Upload file
aws s3 cp file.txt s3://$(terraform output app_bucket_name)/
```

## Troubleshooting

### State Lock Issues

```bash
# See state locks
terraform force-unlock <LOCK_ID>
```

### Resource Already Exists

```bash
# Import existing resource
terraform import module.vpc.aws_vpc.main vpc-12345678
```

### Permission Errors

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user
```

### Terraform Not Finding State

```bash
# Reconfigure backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state
```

## Best Practices

1. **Always run plan first**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

2. **Use version control**
   ```bash
   git commit -m "Update infrastructure configuration"
   ```

3. **Keep state secure**
   - Enable S3 encryption
   - Enable versioning
   - Restrict access

4. **Document changes**
   - Add comments to configuration
   - Update README
   - Track decisions in git

5. **Monitor resources**
   - Enable CloudWatch
   - Set up alarms
   - Review logs

## Support

For issues or questions:
1. Check logs: `terraform output`
2. Review AWS console
3. Check Terraform documentation
4. Contact DevOps team

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)
