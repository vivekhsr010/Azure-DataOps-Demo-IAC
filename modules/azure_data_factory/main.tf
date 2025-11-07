# Azure Data Factory Module - Minimal Setup
# Creates a simple Azure Data Factory instance with essential linked services
# Focuses on core functionality: ADF + Databricks + ADLS + Key Vault integration

# Azure Data Factory - Minimal Configuration
resource "azurerm_data_factory" "main" {
  name                = var.data_factory_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Managed Identity for secure authentication
  identity {
    type = "SystemAssigned"
  }

  # Simple public access (can be disabled later)
  public_network_enabled = true

  tags = merge(var.tags, {
    Service = "DataFactory"
    Module  = "azure_data_factory"
  })
}

# Linked Service - Azure Data Lake Storage Gen2
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "datalake" {
  name            = "${var.data_factory_name}-adls-linked-service"
  data_factory_id = azurerm_data_factory.main.id
  url             = var.datalake_url
  
  # Use managed identity for secure authentication
  use_managed_identity = true

  depends_on = [azurerm_data_factory.main]
}

# Linked Service - Azure Key Vault
resource "azurerm_data_factory_linked_service_key_vault" "keyvault" {
  name            = "${var.data_factory_name}-kv-linked-service"
  data_factory_id = azurerm_data_factory.main.id
  key_vault_id    = var.key_vault_id

  depends_on = [azurerm_data_factory.main]
}

# Linked Service - Azure Databricks
resource "azurerm_data_factory_linked_service_azure_databricks" "databricks" {
  name                       = "${var.data_factory_name}-databricks-linked-service"
  data_factory_id           = azurerm_data_factory.main.id
  description               = "Azure Databricks Linked Service for ${var.data_factory_name}"
  adb_domain                = var.databricks_workspace_url
  msi_work_space_resource_id = var.databricks_workspace_id
  
  # Use existing cluster if provided, otherwise will use job clusters
  existing_cluster_id = var.databricks_cluster_id

  depends_on = [azurerm_data_factory.main]
}

# Optional: Diagnostic Settings for monitoring (recommended)
resource "azurerm_monitor_diagnostic_setting" "data_factory" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.data_factory_name}-diagnostics"
  target_resource_id         = azurerm_data_factory.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Essential logs for monitoring
  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "PipelineRuns"
  }

  enabled_log {
    category = "TriggerRuns"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [azurerm_data_factory.main]
}