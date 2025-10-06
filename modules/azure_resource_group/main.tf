resource "azurerm_resource_group" "this_rg" {
  name     = var.resource_group_name
  location = var.location
    tags     = var.tags
}