output "keyvault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.this_keyvault.id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.this_keyvault.vault_uri
}

output "keyvault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this_keyvault.name
}

output "keyvault_resource_id" {
  description = "The resource ID of the Key Vault"
  value       = azurerm_key_vault.this_keyvault.id
}