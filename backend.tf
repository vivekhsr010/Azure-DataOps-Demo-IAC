terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterrastate43879"
    container_name       = "tfstate"
    key                  = "analytics/terraform.tfstate"
  }
}

# Alternative: Use environment variables or backend config file
# Create backend.hcl file with:
# resource_group_name  = "rg-terraform-state"
# storage_account_name = "stterraformstate" 
# container_name       = "tfstate"
# key                  = "analytics/terraform.tfstate"
#
# Then run: terraform init -backend-config=backend.hcl