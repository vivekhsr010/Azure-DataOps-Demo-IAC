resource "azurerm_key_vault" "this_keyvault" {
  name                = var.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  network_acls {
    default_action = var.network_acls_default_action
    bypass         = var.network_acls_bypass
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    # Key Management Operations - Full permissions
    key_permissions = [
      "Get",
      "List", 
      "Update",
      "Create",
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Rotate",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    # Secret Management Operations - Full permissions  
    secret_permissions = [
      "Get",
      "List",
      "Set", 
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]

    # Certificate Management Operations - Full permissions
    certificate_permissions = [
      "Get",
      "List",
      "Update",
      "Create", 
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "ManageContacts",
      "ManageIssuers",
      "GetIssuers",
      "ListIssuers",
      "SetIssuers",
      "DeleteIssuers"
    ]
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}

# Service Principal secrets will be managed manually
# You can add them manually using Azure CLI or Azure Portal after deployment

# Example secrets that might be useful for your setup
resource "azurerm_key_vault_secret" "databricks_token" {
  count        = var.create_sample_secrets ? 1 : 0
  name         = "databricks-access-token"
  value        = "placeholder-token-to-be-updated"
  key_vault_id = azurerm_key_vault.this_keyvault.id

  depends_on = [azurerm_key_vault.this_keyvault]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  count        = var.create_sample_secrets ? 1 : 0
  name         = "storage-connection-string"
  value        = "placeholder-connection-string-to-be-updated"
  key_vault_id = azurerm_key_vault.this_keyvault.id

  depends_on = [azurerm_key_vault.this_keyvault]
}