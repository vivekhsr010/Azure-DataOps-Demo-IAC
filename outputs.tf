# Resource Group Outputs
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.resource_group_name
}

# Data Lake Storage Outputs
output "storage_account_id" {
  description = "The ID of the storage account"
  value       = module.datalake_storage.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.datalake_storage.storage_account_name
}

# Databricks Outputs
output "databricks_workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = module.databricks_workspace.workspace_id
}

output "databricks_workspace_url" {
  description = "The URL of the Databricks workspace"
  value       = module.databricks_workspace.workspace_url
}

# Key Vault Outputs
output "keyvault_id" {
  description = "The ID of the Key Vault"
  value       = module.azure_keyvault.keyvault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault"
  value       = module.azure_keyvault.keyvault_uri
}

output "keyvault_name" {
  description = "The name of the Key Vault"
  value       = module.azure_keyvault.keyvault_name
}

# Service Principal will be managed manually
