output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this_rg.id
}  

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this_rg.name
}
