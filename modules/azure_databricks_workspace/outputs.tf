output "workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this_workspace.id
}

output "workspace_url" {
  description = "The URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this_workspace.workspace_url
}

output "workspace_name" {
  description = "The name of the Databricks workspace"
  value       = azurerm_databricks_workspace.this_workspace.name
}