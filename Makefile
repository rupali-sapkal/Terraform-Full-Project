.PHONY: help init plan apply destroy init-all plan-all apply-all destroy-all validate fmt clean output state refresh

ENVIRONMENT ?= dev
AUTO_APPROVE ?= false

help:
	@echo "Terraform Infrastructure Management"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make init              - Initialize Terraform for dev environment"
	@echo "  make plan              - Plan changes for dev environment"
	@echo "  make apply             - Apply changes to dev environment"
	@echo "  make destroy           - Destroy dev environment"
	@echo ""
	@echo "  make init-all          - Initialize all environments (dev, prod, uat)"
	@echo "  make plan-all          - Plan changes for all environments"
	@echo "  make apply-all         - Apply changes to all environments"
	@echo "  make destroy-all       - Destroy all environments"
	@echo ""
	@echo "  make validate          - Validate Terraform configuration"
	@echo "  make fmt               - Format Terraform code"
	@echo "  make output ENV=dev    - Show outputs for specific environment"
	@echo "  make state ENV=dev     - Show state for specific environment"
	@echo "  make refresh ENV=dev   - Refresh state for specific environment"
	@echo "  make clean             - Clean Terraform cache"
	@echo ""
	@echo "Usage:"
	@echo "  make init ENVIRONMENT=dev"
	@echo "  make plan ENVIRONMENT=prod"
	@echo "  make apply ENVIRONMENT=uat AUTO_APPROVE=true"

init:
	cd environments/$(ENVIRONMENT) && terraform init

init-all:
	cd environments/dev && terraform init
	cd ../prod && terraform init
	cd ../uat && terraform init

plan:
	cd environments/$(ENVIRONMENT) && terraform plan -var-file="terraform.tfvars"

plan-all:
	cd environments/dev && terraform plan -var-file="terraform.tfvars"
	cd ../prod && terraform plan -var-file="terraform.tfvars"
	cd ../uat && terraform plan -var-file="terraform.tfvars"

apply:
ifeq ($(AUTO_APPROVE),true)
	cd environments/$(ENVIRONMENT) && terraform apply -var-file="terraform.tfvars" -auto-approve
else
	cd environments/$(ENVIRONMENT) && terraform apply -var-file="terraform.tfvars"
endif

apply-all:
ifeq ($(AUTO_APPROVE),true)
	cd environments/dev && terraform apply -var-file="terraform.tfvars" -auto-approve
	cd ../prod && terraform apply -var-file="terraform.tfvars" -auto-approve
	cd ../uat && terraform apply -var-file="terraform.tfvars" -auto-approve
else
	cd environments/dev && terraform apply -var-file="terraform.tfvars"
	cd ../prod && terraform apply -var-file="terraform.tfvars"
	cd ../uat && terraform apply -var-file="terraform.tfvars"
endif

destroy:
	cd environments/$(ENVIRONMENT) && terraform destroy -var-file="terraform.tfvars"

destroy-all:
	@echo "WARNING: This will destroy all environments!"
	@echo "Press Ctrl+C to cancel or Enter to continue..."
	@read dummy
	cd environments/dev && terraform destroy -var-file="terraform.tfvars"
	cd ../prod && terraform destroy -var-file="terraform.tfvars"
	cd ../uat && terraform destroy -var-file="terraform.tfvars"

validate:
	terraform fmt -check -recursive .
	cd environments/dev && terraform validate
	cd ../prod && terraform validate
	cd ../uat && terraform validate

fmt:
	terraform fmt -recursive .

output:
	cd environments/$(ENVIRONMENT) && terraform output

state:
	cd environments/$(ENVIRONMENT) && terraform state list

refresh:
	cd environments/$(ENVIRONMENT) && terraform refresh -var-file="terraform.tfvars"

clean:
	rm -rf environments/*/tfplan
	rm -rf environments/*/.terraform
	rm -rf **/.terraform.lock.hcl

.PHONY: help init init-all plan plan-all apply apply-all destroy destroy-all validate fmt output state refresh clean
