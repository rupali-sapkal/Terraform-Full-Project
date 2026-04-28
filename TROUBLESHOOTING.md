# Common Issues & Solutions

## State Management Issues

### State Lock Error
**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# List locks
aws dynamodb scan --table-name terraform-locks-dev

# Force unlock (be careful!)
terraform force-unlock <LOCK_ID>
```

### State Not Found
**Error:** `Error reading state file`

**Solution:**
```bash
# Reinitialize
terraform init -reconfigure

# Check S3 bucket
aws s3 ls s3://terraform-state-dev-ACCOUNT_ID/

# Migrate state
terraform init -migrate-state
```

---

## AWS & Credentials Issues

### AWS Credentials Not Found
**Error:** `Error: error configuring Terraform AWS Provider: no valid credential sources found`

**Solution:**
```bash
# Check current credentials
aws sts get-caller-identity

# Configure credentials
aws configure

# Use profile
export AWS_PROFILE=myprofile
terraform init
```

### Permission Denied
**Error:** `AccessDenied: User is not authorized to perform`

**Solution:**
```bash
# Check IAM user permissions
aws iam get-user

# Check policy
aws iam list-user-policies --user-name <username>

# Add missing permissions
# - EC2FullAccess
# - S3FullAccess
# - VPCFullAccess
# - IAMFullAccess
# - DynamoDBFullAccess
```

### Region Issues
**Error:** `Error: Unable to determine the AWS region`

**Solution:**
```bash
# Export region
export AWS_REGION=us-east-1

# Or specify in provider
terraform init -var="aws_region=us-east-1"
```

---

## Terraform Configuration Issues

### Module Not Found
**Error:** `Error loading modules: Unable to find the file`

**Solution:**
```bash
# Reinstall modules
terraform init -upgrade

# Check module path
cat environments/dev/main.tf  # verify module source paths
```

### Variable Validation Failed
**Error:** `var.instance_count: a number is required`

**Solution:**
```bash
# Check terraform.tfvars file
cat environments/dev/terraform.tfvars

# Ensure numeric values are not quoted
# Wrong:  instance_count = "2"
# Right:  instance_count = 2
```

### Provider Configuration Error
**Error:** `Error: Provider version constraint not satisfied`

**Solution:**
```bash
# Upgrade providers
terraform init -upgrade

# Specify provider version
terraform providers lock -net-mode=offline
```

---

## Infrastructure Deployment Issues

### Subnet/CIDR Conflicts
**Error:** `Invalid value for 'cidr_block': the specified CIDR block overlaps with another VPC`

**Solution:**
```bash
# Update CIDR in terraform.tfvars
# Change from 10.0.0.0/16 to 10.X.0.0/16

terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Instance Launch Failures
**Error:** `Client.InsufficientInstanceCapacity`

**Solution:**
```bash
# Wait and retry
sleep 30
terraform apply -var-file="terraform.tfvars"

# Change instance type
# Edit terraform.tfvars: instance_type = "t3.small"
# Or use a different AZ in availability_zones
```

### Load Balancer Target Unhealthy
**Error:** `Target instance failing health checks`

**Solution:**
```bash
# Check target group
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check security groups
aws ec2 describe-security-groups

# Verify user_data script execution
aws ssm get-command-invocation --command-id <id> \
  --instance-id <instance-id>
```

---

## S3 State Bucket Issues

### Bucket Already Exists
**Error:** `BucketAlreadyExists: The requested bucket name is not available`

**Solution:**
```bash
# Use different bucket name
# Edit provider.tf: change bucket name

# Or use existing bucket
# terraform init -backend-config="bucket=my-existing-bucket"
```

### Bucket Access Denied
**Error:** `AccessDenied: User is not authorized to perform`

**Solution:**
```bash
# Grant S3 permissions
aws s3 put-bucket-policy --bucket terraform-state-dev-ACCOUNT_ID \
  --policy file://bucket-policy.json
```

### Enable Encryption Failed
**Error:** `ServerSideEncryptionConfigurationNotFound`

**Solution:**
```bash
# Enable encryption manually
aws s3api put-bucket-encryption \
  --bucket terraform-state-dev-ACCOUNT_ID \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

---

## Jenkins Pipeline Issues

### Pipeline Timeout
**Error:** `Build timed out after 60 minutes`

**Solution:**
```groovy
// In Jenkinsfile, increase timeout
options {
    timeout(time: 120, unit: 'MINUTES')  // Increase to 120 minutes
}
```

### AWS Credentials Not Found in Jenkins
**Error:** `Unable to find AWS credentials`

**Solution:**
1. Manage Jenkins → Manage Credentials
2. Add AWS Credentials
3. Set Credentials ID: `aws-terraform-credentials`
4. Update Jenkinsfile to use correct credentials ID

### TFLint Installation Fails
**Error:** `command not found: tflint`

**Solution:**
```bash
# Install on Jenkins agent
curl -sSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Update Jenkinsfile to skip TFLint if not available
# Add: if ! command -v tflint &> /dev/null
```

---

## Resource Destruction Issues

### Cannot Destroy (Resource in Use)
**Error:** `InvalidGroup.InUse: The security group is in use`

**Solution:**
```bash
# Remove dependencies first
# Usually: ALB → Target Group → Security Group → EC2 → VPC

# Force destroy (not recommended for production)
terraform destroy -var-file="terraform.tfvars" -force
```

### Terraform State Out of Sync
**Error:** `Resource exists in AWS but not in Terraform state`

**Solution:**
```bash
# Import the resource
terraform import module.vpc.aws_vpc.main vpc-12345678

# Or remove from state
terraform state rm module.vpc.aws_vpc.main

# Check state
terraform state list
```

---

## Performance Issues

### Terraform Commands Are Slow
**Solution:**
```bash
# Increase log level for debugging
export TF_LOG=DEBUG

# Use -parallelism flag
terraform apply -parallelism=10 -var-file="terraform.tfvars"

# Check AWS API rate limits
aws service-quotas list-service-quotas --service-code ec2
```

### Long Apply Times
**Solution:**
```bash
# Deploy in smaller batches
# Increase instance_count gradually

# Use targeted apply
terraform apply -target=module.ec2 -var-file="terraform.tfvars"
```

---

## Getting Help

### Enable Debug Logging
```bash
export TF_LOG=DEBUG
terraform init
terraform plan
```

### Check Terraform Version
```bash
terraform version
aws --version
```

### Validate Configuration
```bash
terraform validate
terraform fmt -check -recursive
```

### Test AWS Connection
```bash
aws sts get-caller-identity
aws ec2 describe-regions
```

---

## Contact & Escalation

For unresolved issues:
1. Enable debug logging
2. Collect error messages and logs
3. Review AWS CloudTrail for API errors
4. Contact DevOps team with:
   - Error message
   - Terraform logs
   - Environment name
   - Last successful action
