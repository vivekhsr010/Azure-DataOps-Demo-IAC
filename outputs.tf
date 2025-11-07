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

# Cost Monitoring Outputs
output "monitoring_summary" {
  description = "Cost monitoring configuration summary"
  value       = var.enable_cost_monitoring ? module.cost_monitoring[0].monitoring_summary : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for cost monitoring"
  value       = var.enable_cost_monitoring ? module.cost_monitoring[0].log_analytics_workspace_id : null
}

output "monthly_budget_id" {
  description = "Monthly budget configuration ID"
  value       = var.enable_cost_monitoring ? module.cost_monitoring[0].monthly_budget_id : null
}

# Deployment Instructions
output "deployment_summary" {
  description = "Summary of deployed resources and next steps"
  value = {
    resource_group      = module.resource_group.resource_group_name
    storage_account     = module.datalake_storage.storage_account_name
    key_vault          = module.azure_keyvault.keyvault_name
    databricks_workspace = module.databricks_workspace.workspace_url
    data_factory       = var.enable_data_factory ? module.data_factory[0].data_factory_name : "Not deployed"
    monitoring_enabled = var.enable_cost_monitoring
    team_size         = var.enable_cost_monitoring ? length(var.team_email_addresses) : 0
    monthly_budget    = var.enable_cost_monitoring ? var.monthly_budget_limit : 0
  }
}

# ===================================
# Azure Data Factory Outputs
# ===================================

output "data_factory_details" {
  description = "Azure Data Factory configuration details"
  value = var.enable_data_factory ? {
    id                = module.data_factory[0].data_factory_id
    name              = module.data_factory[0].data_factory_name
    location          = module.data_factory[0].data_factory_location
    resource_group    = module.data_factory[0].data_factory_resource_group_name
    principal_id      = module.data_factory[0].data_factory_principal_id
    configuration     = module.data_factory[0].data_factory_configuration
  } : null
}

output "data_factory_linked_services" {
  description = "Azure Data Factory linked services information"
  value = var.enable_data_factory ? {
    datalake_gen2 = {
      id   = module.data_factory[0].datalake_linked_service_id
      name = module.data_factory[0].datalake_linked_service_name
    }
    key_vault = {
      id   = module.data_factory[0].keyvault_linked_service_id
      name = module.data_factory[0].keyvault_linked_service_name
    }
    databricks = {
      id   = module.data_factory[0].databricks_linked_service_id
      name = module.data_factory[0].databricks_linked_service_name
    }
  } : null
}
