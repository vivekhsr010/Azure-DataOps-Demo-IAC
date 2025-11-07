# Azure Data Factory Module Outputs - Minimal Configuration
# Essential outputs for integration with other modules

# Data Factory Basic Information
output "data_factory_id" {
  description = "The ID of the Azure Data Factory"
  value       = azurerm_data_factory.main.id
}

output "data_factory_name" {
  description = "The name of the Azure Data Factory"
  value       = azurerm_data_factory.main.name
}

output "data_factory_location" {
  description = "The location of the Azure Data Factory"
  value       = azurerm_data_factory.main.location
}

output "data_factory_resource_group_name" {
  description = "The resource group name of the Azure Data Factory"
  value       = azurerm_data_factory.main.resource_group_name
}

# Managed Identity Information
output "data_factory_principal_id" {
  description = "The principal ID of the Data Factory's managed identity (for RBAC assignments)"
  value       = azurerm_data_factory.main.identity[0].principal_id
}

output "data_factory_identity" {
  description = "The managed identity configuration of the Data Factory"
  value = {
    type         = azurerm_data_factory.main.identity[0].type
    principal_id = azurerm_data_factory.main.identity[0].principal_id
    tenant_id    = azurerm_data_factory.main.identity[0].tenant_id
  }
}

# Linked Services Information
output "datalake_linked_service_id" {
  description = "The ID of the Data Lake Storage Gen2 linked service"
  value       = azurerm_data_factory_linked_service_data_lake_storage_gen2.datalake.id
}

output "datalake_linked_service_name" {
  description = "The name of the Data Lake Storage Gen2 linked service"
  value       = azurerm_data_factory_linked_service_data_lake_storage_gen2.datalake.name
}

output "keyvault_linked_service_id" {
  description = "The ID of the Key Vault linked service"
  value       = azurerm_data_factory_linked_service_key_vault.keyvault.id
}

output "keyvault_linked_service_name" {
  description = "The name of the Key Vault linked service"
  value       = azurerm_data_factory_linked_service_key_vault.keyvault.name
}

output "databricks_linked_service_id" {
  description = "The ID of the Databricks linked service"
  value       = azurerm_data_factory_linked_service_azure_databricks.databricks.id
}

output "databricks_linked_service_name" {
  description = "The name of the Databricks linked service"
  value       = azurerm_data_factory_linked_service_azure_databricks.databricks.name
}

# Configuration Summary
output "data_factory_configuration" {
  description = "Summary of Data Factory configuration"
  value = {
    name                    = azurerm_data_factory.main.name
    location               = azurerm_data_factory.main.location
    resource_group_name    = azurerm_data_factory.main.resource_group_name
    public_network_enabled = azurerm_data_factory.main.public_network_enabled
    managed_identity_principal_id = azurerm_data_factory.main.identity[0].principal_id
    linked_services = {
      datalake_gen2 = azurerm_data_factory_linked_service_data_lake_storage_gen2.datalake.name
      key_vault     = azurerm_data_factory_linked_service_key_vault.keyvault.name
      databricks    = azurerm_data_factory_linked_service_azure_databricks.databricks.name
    }
    monitoring_enabled = var.enable_diagnostic_settings
  }
}