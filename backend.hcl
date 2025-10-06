# Backend configuration for Terraform state
# Use: terraform init -reconfigure

resource_group_name  = "rg-terraform-state"
storage_account_name = "stterrastate43879"
container_name       = "tfstate"
key                  = "analytics/terraform.tfstate"