#!/bin/bash

###############################################################################
# Terraform Multi-Environment Management Script
# Simplifies common Terraform operations across environments
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENTS=("dev" "prod" "uat")
CURRENT_DIR=$(pwd)

# Functions
print_usage() {
    cat << EOF
Usage: $0 [COMMAND] [ENVIRONMENT] [OPTIONS]

COMMANDS:
    init        Initialize Terraform for environment
    plan        Plan infrastructure changes
    apply       Apply infrastructure changes
    destroy     Destroy infrastructure
    output      Show Terraform outputs
    validate    Validate Terraform configuration
    fmt         Format Terraform code
    state       Show Terraform state
    refresh     Refresh Terraform state
    workspace   List workspaces
    cost        Estimate infrastructure cost

ENVIRONMENTS:
    dev         Development environment
    prod        Production environment
    uat         UAT environment
    all         Run command on all environments

OPTIONS:
    -auto-approve    Auto approve apply/destroy
    -refresh         Refresh state before plan/apply
    -var             Pass Terraform variable (e.g., -var instance_count=4)

EXAMPLES:
    $0 init dev
    $0 plan dev
    $0 apply prod -auto-approve
    $0 destroy uat
    $0 output dev
    $0 fmt all

EOF
    exit 1
}

# Check if environment is valid
validate_environment() {
    local env=$1
    for valid_env in "${ENVIRONMENTS[@]}" "all"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    echo -e "${RED}Error: Invalid environment '$env'${NC}"
    echo "Valid environments: ${ENVIRONMENTS[*]} all"
    exit 1
}

# Execute command in directory
exec_terraform() {
    local command=$1
    local env=$2
    shift 2
    local extra_args="$@"

    if [[ "$env" == "all" ]]; then
        for current_env in "${ENVIRONMENTS[@]}"; do
            exec_terraform "$command" "$current_env" "${extra_args}"
        done
        return 0
    fi

    echo -e "${BLUE}========== $command ($env) ==========${NC}"
    cd "$CURRENT_DIR/environments/$env"

    case $command in
        init)
            terraform init
            ;;
        plan)
            terraform plan -var-file="terraform.tfvars" $extra_args
            ;;
        apply)
            if [[ "$extra_args" == *"-auto-approve"* ]]; then
                terraform apply -var-file="terraform.tfvars" -auto-approve $extra_args
            else
                terraform apply -var-file="terraform.tfvars" $extra_args
            fi
            ;;
        destroy)
            if [[ "$extra_args" == *"-auto-approve"* ]]; then
                terraform destroy -var-file="terraform.tfvars" -auto-approve $extra_args
            else
                terraform destroy -var-file="terraform.tfvars" $extra_args
            fi
            ;;
        output)
            terraform output $extra_args
            ;;
        validate)
            terraform validate $extra_args
            ;;
        fmt)
            terraform fmt -recursive $extra_args
            ;;
        state)
            terraform state $extra_args
            ;;
        refresh)
            terraform refresh -var-file="terraform.tfvars" $extra_args
            ;;
        workspace)
            terraform workspace list $extra_args
            ;;
        cost)
            echo -e "${YELLOW}Estimated monthly costs:${NC}"
            echo "Development (t3.micro):  ~$50-80/month"
            echo "Production (t3.small):   ~$80-120/month"
            echo "UAT (t3.micro):          ~$50-80/month"
            echo "S3 & DynamoDB:           ~$1-5/month"
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            print_usage
            ;;
    esac

    cd "$CURRENT_DIR"
    echo -e "${GREEN}✓ Command completed${NC}"
    echo ""
}

# Main execution
if [[ $# -lt 1 ]]; then
    print_usage
fi

COMMAND=$1
ENVIRONMENT=${2:-dev}

validate_environment "$ENVIRONMENT"

# Extract remaining arguments
shift 2
EXTRA_ARGS="$@"

exec_terraform "$COMMAND" "$ENVIRONMENT" $EXTRA_ARGS
