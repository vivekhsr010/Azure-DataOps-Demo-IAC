# Get current client configuration
data "azurerm_client_config" "current" {}

# Get current subscription
data "azurerm_subscription" "current" {}