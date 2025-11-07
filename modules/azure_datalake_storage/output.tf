output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.datalake_storage.name
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.datalake_storage.id
}

output "name" {
  description = "The name of the storage account (legacy)"
  value       = azurerm_storage_account.datalake_storage.name
}

output "primary_dfs_endpoint" {
  description = "The primary DFS endpoint URL for the storage account"
  value       = azurerm_storage_account.datalake_storage.primary_dfs_endpoint
}