resource "azurerm_storage_account" "datalake_storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"
  is_hns_enabled          = true  # Enable hierarchical namespace   
    tags                    = var.tags  
}   