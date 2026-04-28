#!/bin/bash

###############################################################################
# Terraform Backend Setup Script
# This script automates the creation of S3 buckets and DynamoDB tables
# for Terraform state management
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ENVIRONMENTS=("dev" "prod" "uat")

echo -e "${YELLOW}========== Terraform Backend Setup ==========${NC}"
echo -e "AWS Account ID: ${GREEN}${ACCOUNT_ID}${NC}"
echo -e "Region: ${GREEN}${REGION}${NC}"
echo ""

# Function to create S3 bucket
create_s3_bucket() {
    local env=$1
    local bucket_name="terraform-state-${env}-${ACCOUNT_ID}"
    
    echo -e "${YELLOW}Creating S3 bucket: ${GREEN}${bucket_name}${NC}"
    
    # Create bucket
    if aws s3 mb "s3://${bucket_name}" --region $REGION 2>/dev/null; then
        echo -e "${GREEN}✓ S3 bucket created${NC}"
    else
        echo -e "${YELLOW}✓ S3 bucket already exists${NC}"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    echo -e "${GREEN}✓ Versioning enabled${NC}"
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' 2>/dev/null || true
    echo -e "${GREEN}✓ Encryption enabled${NC}"
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    echo -e "${GREEN}✓ Public access blocked${NC}"
    
    echo ""
}

# Function to create DynamoDB table
create_dynamodb_table() {
    local env=$1
    local table_name="terraform-locks-${env}"
    
    echo -e "${YELLOW}Creating DynamoDB table: ${GREEN}${table_name}${NC}"
    
    if aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION 2>/dev/null; then
        echo -e "${GREEN}✓ DynamoDB table created${NC}"
    else
        echo -e "${YELLOW}✓ DynamoDB table already exists${NC}"
    fi
    
    echo ""
}

# Main execution
echo -e "${YELLOW}Setting up S3 buckets...${NC}"
echo ""
for ENV in "${ENVIRONMENTS[@]}"; do
    create_s3_bucket "$ENV"
done

echo -e "${YELLOW}Setting up DynamoDB tables...${NC}"
echo ""
for ENV in "${ENVIRONMENTS[@]}"; do
    create_dynamodb_table "$ENV"
done

# Summary
echo -e "${YELLOW}========== Setup Summary ==========${NC}"
echo ""
echo -e "${GREEN}S3 Buckets Created:${NC}"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "  - terraform-state-${ENV}-${ACCOUNT_ID}"
done

echo ""
echo -e "${GREEN}DynamoDB Tables Created:${NC}"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "  - terraform-locks-${ENV}"
done

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update provider.tf files with your Account ID:"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "   sed -i 's/ACCOUNT_ID/${ACCOUNT_ID}/g' environments/${ENV}/provider.tf"
done

echo ""
echo "2. Run: terraform init from each environment directory"
echo ""
echo -e "${GREEN}✓ Backend setup completed!${NC}"
