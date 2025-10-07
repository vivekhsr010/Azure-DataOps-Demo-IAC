# =============================================================================
# AZURE ANALYTICS MONITORING MODULE
# =============================================================================
# This module provides comprehensive monitoring for:
# - Storage Account: Availability, transactions, and capacity metrics
# - Key Vault: API availability, request patterns, and audit logging  
# - Databricks: CPU, memory, disk, job failures, and cluster performance
# - Log Analytics: Data ingestion and usage patterns
# - Infrastructure: Resource health and cost management
# =============================================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  
  # Enable data ingestion and querying
  daily_quota_gb                     = -1  # Unlimited
  reservation_capacity_in_gb_per_day = null
  internet_ingestion_enabled         = true
  internet_query_enabled            = true
  local_authentication_disabled     = false

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
  count                     = var.storage_account_id != null ? 1 : 0
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
  count                     = var.keyvault_id != null ? 1 : 0
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

# Storage Account Monitoring Alerts
resource "azurerm_monitor_metric_alert" "storage_availability" {
  count               = var.enable_alerts && var.storage_account_id != null ? 1 : 0
  name                = "storage-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  description         = "Alert when storage account availability drops below threshold"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "storage_transactions" {
  count               = var.enable_alerts && var.storage_account_id != null ? 1 : 0
  name                = "storage-high-transactions-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  description         = "Alert when storage transactions are unusually high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Key Vault Monitoring Alerts
resource "azurerm_monitor_metric_alert" "keyvault_availability" {
  count               = var.enable_alerts && var.keyvault_id != null ? 1 : 0
  name                = "keyvault-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.keyvault_id]
  description         = "Alert when Key Vault availability drops below threshold"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiHit"
    aggregation      = "Count"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "keyvault_requests" {
  count               = var.enable_alerts && var.keyvault_id != null ? 1 : 0
  name                = "keyvault-high-requests-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.keyvault_id]
  description         = "Alert when Key Vault requests are unusually high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiHit"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Log Analytics Workspace Monitoring - Using query instead of metric
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_ingestion" {
  count               = var.enable_alerts ? 1 : 0
  name                = "log-analytics-high-ingestion-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration     = "PT15M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      Usage
      | where TimeGenerated > ago(15m)
      | summarize TotalGB = sum(Quantity) / 1000
      | where TotalGB > 5
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Alert when Log Analytics data ingestion is unusually high (>5GB in 15 minutes)"
  display_name          = "Log Analytics High Ingestion"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Databricks Workspace Monitoring
resource "azurerm_monitor_diagnostic_setting" "databricks" {
  count                     = var.databricks_workspace_id != null ? 1 : 0
  name                      = "databricks-diagnostics"
  target_resource_id        = var.databricks_workspace_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "dbfs"
  }

  enabled_log {
    category = "clusters"
  }

  enabled_log {
    category = "accounts"
  }

  enabled_log {
    category = "jobs"
  }

  enabled_log {
    category = "notebook"
  }

  enabled_log {
    category = "ssh"
  }

  enabled_log {
    category = "workspace"
  }
}

# Databricks Performance Monitoring Alerts
# These monitor the underlying compute resources through Log Analytics queries

# CPU Utilization Alert for Databricks Clusters
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "databricks_high_cpu" {
  count               = var.enable_alerts && var.databricks_workspace_id != null ? 1 : 0
  name                = "databricks-high-cpu-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration     = "PT15M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      DatabricksWorkspace
      | where Category == "clusters"
      | summarize HighUsage = count() by bin(TimeGenerated, 5m)
      | where HighUsage > 0
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 2
      number_of_evaluation_periods             = 3
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Alert when Databricks cluster CPU utilization is consistently high"
  display_name          = "Databricks High CPU Usage"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Memory Utilization Alert for Databricks Clusters  
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "databricks_high_memory" {
  count               = var.enable_alerts && var.databricks_workspace_id != null ? 1 : 0
  name                = "databricks-high-memory-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration     = "PT15M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      DatabricksWorkspace
      | where Category == "clusters"
      | summarize MemoryEvents = count() by bin(TimeGenerated, 5m)
      | where MemoryEvents > 0
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 2
      number_of_evaluation_periods             = 3
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Alert when Databricks cluster memory utilization is consistently high"
  display_name          = "Databricks High Memory Usage"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Databricks Job Failure Alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "databricks_job_failures" {
  count               = var.enable_alerts && var.databricks_workspace_id != null ? 1 : 0
  name                = "databricks-job-failures-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration     = "PT30M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 1
  
  criteria {
    query                   = <<-QUERY
      DatabricksWorkspace
      | where Category == "jobs" and OperationName contains "runFailed"
      | summarize FailedJobs = count() by bin(TimeGenerated, 5m)
      | where FailedJobs >= 1
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1  
    }
  }
  
  auto_mitigation_enabled = false
  description            = "Alert when Databricks jobs fail"
  display_name          = "Databricks Job Failures"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Databricks Cluster Startup Time Alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "databricks_slow_startup" {
  count               = var.enable_alerts && var.databricks_workspace_id != null ? 1 : 0
  name                = "databricks-slow-startup-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT15M"
  window_duration     = "PT1H"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      DatabricksWorkspace
      | where Category == "clusters" and OperationName contains "start"
      | summarize StartupEvents = count() by bin(TimeGenerated, 15m)
      | where StartupEvents > 0
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 2
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Alert when Databricks cluster startup time is consistently slow (>5 minutes)"
  display_name          = "Databricks Slow Cluster Startup"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Databricks Disk Space Alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "databricks_disk_space" {
  count               = var.enable_alerts && var.databricks_workspace_id != null ? 1 : 0
  name                = "databricks-disk-space-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT10M"
  window_duration     = "PT30M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      DatabricksWorkspace
      | where Category == "clusters"
      | summarize DiskEvents = count() by bin(TimeGenerated, 10m)
      | where DiskEvents > 0
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 2
      number_of_evaluation_periods             = 3
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Alert when Databricks cluster disk usage exceeds 85%"
  display_name          = "Databricks High Disk Usage"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Log Analytics Connectivity Test Query
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_connectivity" {
  count               = var.enable_alerts ? 1 : 0
  name                = "log-analytics-connectivity-test"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration     = "PT10M"
  scopes             = [azurerm_log_analytics_workspace.main.id]
  severity           = 3  # Informational
  
  criteria {
    query                   = <<-QUERY
      Heartbeat
      | where TimeGenerated > ago(10m)
      | summarize LastHeartbeat = max(TimeGenerated)
      | extend MinutesAgo = datetime_diff('minute', now(), LastHeartbeat)
      | where MinutesAgo > 15
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  auto_mitigation_enabled = true
  description            = "Test query to verify Log Analytics is receiving data"
  display_name          = "Log Analytics Connectivity Test"
  
  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = var.tags
}

# Resource Health Monitoring
resource "azurerm_monitor_activity_log_alert" "resource_health" {
  count               = var.enable_alerts ? 1 : 0
  name                = "resource-health-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"]
  description         = "Alert when any resource in the resource group has health issues"

  criteria {
    category = "ResourceHealth"
    
    resource_health {
      current = ["Unavailable", "Degraded"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Budget Alert for Cost Management
resource "azurerm_monitor_activity_log_alert" "cost_alert" {
  count               = var.enable_alerts ? 1 : 0
  name                = "high-cost-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"]
  description         = "Alert for unusual resource creation that might impact costs"

  criteria {
    category = "Administrative"
    operation_name = "Microsoft.Resources/deployments/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Local values for monitoring configuration
locals {
  # Ensure all monitoring components are properly connected
  monitoring_enabled = var.enable_alerts && var.alert_email != ""
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  count               = var.enable_alerts ? 1 : 0
  name                = "monitoring-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "mon-alerts"

  email_receiver {
    name                    = "admin"
    email_address          = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}