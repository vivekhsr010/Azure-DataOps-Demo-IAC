locals {
  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    Owner       = data.azurerm_client_config.current.object_id
  })

  # Naming convention
  naming_prefix = "${var.project_name}-${var.environment}"

  # Resource naming with validation
  resource_names = {
    resource_group    = "rg-${local.naming_prefix}"
    storage_account   = replace("st${local.naming_prefix}${random_integer.storage_suffix.result}", "-", "")
    keyvault          = "kv-${local.naming_prefix}-${random_integer.kv_suffix.result}"
    databricks        = "dbw-${local.naming_prefix}"
    service_principal = "sp-${local.naming_prefix}-datalake"
    log_analytics     = "log-${local.naming_prefix}"
  }

  # Current timestamp for resource lifecycle management
  deployment_timestamp = timestamp()
}

# Random suffixes for globally unique resources
resource "random_integer" "storage_suffix" {
  min = 1000
  max = 9999
}

resource "random_integer" "kv_suffix" {
  min = 100
  max = 999
}