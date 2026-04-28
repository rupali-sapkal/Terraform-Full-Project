# Backend Configuration Setup Guide

This guide helps you set up the backend infrastructure for storing Terraform state in AWS S3 with DynamoDB for state locking.

## Prerequisites

- AWS CLI installed and configured
- Appropriate AWS permissions
- jq (for JSON parsing, optional)

## Automated Setup

### Run the setup script:

```bash
#!/bin/bash

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ENVIRONMENTS=("dev" "prod" "uat")

echo "Setting up Terraform backend infrastructure..."
echo "AWS Account ID: $ACCOUNT_ID"
echo "Region: $REGION"

# Create S3 buckets and enable versioning
for ENV in "${ENVIRONMENTS[@]}"; do
    BUCKET_NAME="terraform-state-${ENV}-${ACCOUNT_ID}"
    
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb "s3://${BUCKET_NAME}" --region $REGION 2>/dev/null || echo "Bucket already exists: $BUCKET_NAME"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo "✓ S3 bucket configured: $BUCKET_NAME"
done

# Create DynamoDB tables for state locking
for ENV in "${ENVIRONMENTS[@]}"; do
    TABLE_NAME="terraform-locks-${ENV}"
    
    echo "Creating DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION 2>/dev/null || echo "Table already exists: $TABLE_NAME"
    
    echo "✓ DynamoDB table created: $TABLE_NAME"
done

echo ""
echo "✓ Backend infrastructure setup completed!"
echo ""
echo "Update provider.tf files with your Account ID: $ACCOUNT_ID"
echo ""
echo "sed command templates:"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "sed -i 's/ACCOUNT_ID/${ACCOUNT_ID}/g' environments/${ENV}/provider.tf"
done
```

## Manual Setup Steps

### 1. Create S3 Bucket for Dev

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://terraform-state-dev-${ACCOUNT_ID} --region us-east-1
```

### 2. Enable Versioning

```bash
aws s3api put-bucket-versioning \
  --bucket terraform-state-dev-${ACCOUNT_ID} \
  --versioning-configuration Status=Enabled
```

### 3. Enable Encryption

```bash
aws s3api put-bucket-encryption \
  --bucket terraform-state-dev-${ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 4. Block Public Access

```bash
aws s3api put-public-access-block \
  --bucket terraform-state-dev-${ACCOUNT_ID} \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 5. Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Verify Backend Setup

```bash
# List S3 buckets
aws s3 ls | grep terraform-state

# Check DynamoDB tables
aws dynamodb list-tables --region us-east-1
```

## Troubleshooting

### Bucket Already Exists Error
Solution: Use a different bucket name or delete the existing bucket first

### Access Denied Error
Solution: Verify your AWS credentials and IAM permissions

### DynamoDB Table Exists Error
Solution: The table already exists; continue to the next step
