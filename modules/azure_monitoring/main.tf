# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "other"

  tags = var.tags
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                      = "storage-diagnostics"
  target_resource_id        = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Storage accounts only support metrics, not logs in newer API versions
  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                      = "keyvault-diagnostics"
  target_resource_id        = var.keyvault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Alerts for Service Principal Password Expiry
resource "azurerm_monitor_metric_alert" "sp_password_expiry" {
  count               = var.enable_alerts ? 1 : 0
  name                = "sp-password-expiry-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.main.id]
  description         = "Alert when service principal password is about to expire"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Heartbeat"
    aggregation      = "Count"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  count               = var.enable_alerts ? 1 : 0
  name                = "monitoring-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "mon-alerts"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }

  tags = var.tags
}