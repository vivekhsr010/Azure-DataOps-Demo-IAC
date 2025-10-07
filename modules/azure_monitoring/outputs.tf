output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_id" {
  description = "The ID of the Application Insights component"
  value       = azurerm_application_insights.main.id
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key of Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "action_group_id" {
  description = "The ID of the monitoring action group"
  value       = var.enable_alerts ? azurerm_monitor_action_group.main[0].id : null
}

output "monitoring_alerts_configured" {
  description = "List of configured monitoring alerts"
  value = var.enable_alerts ? concat([
    "Storage Availability Alert",
    "Storage High Transactions Alert", 
    "Key Vault Availability Alert",
    "Key Vault High Requests Alert",
    "Log Analytics High Ingestion Alert",
    "Resource Health Alert",
    "Cost Management Alert"
  ], var.databricks_workspace_id != null ? [
    "Databricks High CPU Usage Alert",
    "Databricks High Memory Usage Alert", 
    "Databricks Job Failures Alert",
    "Databricks Slow Startup Alert",
    "Databricks High Disk Usage Alert"
  ] : []) : []
}

output "diagnostic_settings_configured" {
  description = "List of resources with diagnostic settings configured"
  value = compact([
    var.storage_account_id != null ? "Storage Account" : null,
    var.keyvault_id != null ? "Key Vault" : null,
    var.databricks_workspace_id != null ? "Databricks Workspace" : null
  ])
}

output "monitoring_health_check" {
  description = "Health check status of all monitoring components"
  value = {
    log_analytics_workspace = {
      configured = true
      workspace_id = azurerm_log_analytics_workspace.main.id
      retention_days = azurerm_log_analytics_workspace.main.retention_in_days
      daily_quota_gb = azurerm_log_analytics_workspace.main.daily_quota_gb
    }
    application_insights = {
      configured = true
      app_id = azurerm_application_insights.main.app_id
      connected_to_workspace = true
    }
    action_group = {
      configured = var.enable_alerts
      email_configured = var.alert_email != ""
      email_address = var.enable_alerts ? var.alert_email : "Not configured"
    }
    diagnostic_settings = {
      storage_account = var.storage_account_id != null
      key_vault = var.keyvault_id != null
      databricks_workspace = var.databricks_workspace_id != null
    }
    alerts_summary = {
      total_alerts = length(var.enable_alerts ? concat([
        "Storage Availability", "Storage Transactions", "Key Vault Availability", "Key Vault Requests",
        "Log Analytics Ingestion", "Resource Health", "Cost Management", "Connectivity Test"
      ], var.databricks_workspace_id != null ? [
        "Databricks CPU", "Databricks Memory", "Databricks Jobs", "Databricks Startup", "Databricks Disk"
      ] : []) : [])
      databricks_monitoring_enabled = var.databricks_workspace_id != null && var.enable_alerts
    }
  }
}