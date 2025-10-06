terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.91.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "azurerm" {
  features {}
}

provider "databricks" {
  alias = "workspace"
  # This provider will be configured dynamically when workspace is available
  host = var.deploy_databricks_cluster ? module.databricks_workspace.workspace_url : null
}