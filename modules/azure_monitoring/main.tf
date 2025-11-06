# =============================================================================
# AZURE COST & RESOURCE MONITORING MODULE
# =============================================================================
# This module provides team-focused cost and resource monitoring for:
# - Cost Management: Daily and monthly budget alerts with $250 monthly cap
# - Resource Tracking: Creation, modification, and deletion alerts
# - Team Management: 8-member team cost monitoring and governance
# - Email Notifications: End-of-day and monthly cost summaries
# - Subscription-wide: Resource lifecycle monitoring across all services
# =============================================================================

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Log Analytics Workspace for cost and resource monitoring
resource "azurerm_log_analytics_workspace" "cost_monitoring" {
  name                = "${var.project_name}-cost-monitoring-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 90  # 3 months retention for cost analysis
  
  # Enable data ingestion and querying
  daily_quota_gb                     = 10  # Limit daily ingestion to control costs
  internet_ingestion_enabled         = true
  internet_query_enabled            = true

  tags = var.tags
}

# Application Insights for application cost monitoring
resource "azurerm_application_insights" "cost_monitoring" {
  name                = "${var.project_name}-cost-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.cost_monitoring.id
  application_type    = "other"
  sampling_percentage = 100

  tags = var.tags
}

# =============================================================================
# BUDGET CONFIGURATION
# =============================================================================

# Monthly Budget Alert - $250 cap for 8-member team
resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "${var.project_name}-monthly-budget"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  
  amount     = var.monthly_budget_limit
  time_grain = "Monthly"
  
  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h")) # 1 year from now
  }
  
  # Alert at 50%, 75%, 90%, and 100% of budget
  notification {
    enabled   = true
    threshold = 50
    operator  = "GreaterThan"
    
    contact_emails = var.team_email_addresses
    
    threshold_type = "Actual"
  }
  
  notification {
    enabled   = true
    threshold = 75
    operator  = "GreaterThan"
    
    contact_emails = var.team_email_addresses
    
    threshold_type = "Actual"
  }
  
  notification {
    enabled   = true
    threshold = 90
    operator  = "GreaterThan"
    
    contact_emails = var.team_email_addresses
    
    threshold_type = "Actual"
  }
  
  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"
    
    contact_emails = var.team_email_addresses
    
    threshold_type = "Actual"
  }
  
  # Forecast alerts at 80% and 100%
  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"
    
    contact_emails = var.team_email_addresses
    
    threshold_type = "Forecasted"
  }
}

# =============================================================================
# ACTION GROUP FOR NOTIFICATIONS
# =============================================================================

# Main Action Group for all monitoring alerts
resource "azurerm_monitor_action_group" "team_alerts" {
  name                = "${var.project_name}-team-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "team-alert"

  # Email notifications for all team members
  dynamic "email_receiver" {
    for_each = var.team_email_addresses
    content {
      name                    = "team-member-${email_receiver.key + 1}"
      email_address          = email_receiver.value
      use_common_alert_schema = true
    }
  }

  # Optional: Add webhook for Slack/Teams integration
  dynamic "webhook_receiver" {
    for_each = var.webhook_url != "" ? [var.webhook_url] : []
    content {
      name        = "team-webhook"
      service_uri = webhook_receiver.value
    }
  }

  tags = var.tags
}

# =============================================================================
# DAILY COST MONITORING ALERTS
# =============================================================================

# Daily cost alert - triggers at end of day if daily spend > $8.33 (1/30 of monthly budget)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "daily_cost_alert" {
  name                = "${var.project_name}-daily-cost-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "P1D"     # Daily evaluation
  window_duration     = "P1D"     # Look at past 24 hours
  scopes             = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      Usage
      | where TimeGenerated >= ago(1d)
      | where IsBillable == true
      | extend ResourceGroup = tostring(split(ResourceUri, "/")[4])
      | where ResourceGroup == "${var.resource_group_name}"
      | summarize DailyCost = sum(Quantity * UnitPrice) by bin(TimeGenerated, 1d)
      | where DailyCost > ${var.monthly_budget_limit / 30}
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
  description            = "Daily cost exceeded $${var.monthly_budget_limit / 30} threshold (1/30 of monthly $${var.monthly_budget_limit} budget)"
  display_name          = "Daily Cost Alert - End of Day Summary"
  
  action {
    action_groups = [azurerm_monitor_action_group.team_alerts.id]
    
    custom_properties = {
      "alert_type" = "daily_cost"
      "team_size"  = tostring(length(var.team_email_addresses))
      "budget_limit" = tostring(var.monthly_budget_limit)
    }
  }

  tags = var.tags
}

# =============================================================================
# RESOURCE LIFECYCLE MONITORING
# =============================================================================

# Resource Creation Alert
resource "azurerm_monitor_activity_log_alert" "resource_creation" {
  name                = "${var.project_name}-resource-creation-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when new resources are created in the subscription"

  criteria {
    category = "Administrative"
    operation_name = "Microsoft.Resources/subscriptions/resourceGroups/providers/resources/write"
    level = "Informational"
  }

  action {
    action_group_id = azurerm_monitor_action_group.team_alerts.id
    
    webhook_properties = {
      "alert_type" = "resource_creation"
      "team_notification" = "true"
    }
  }

  tags = var.tags
}

# Resource Deletion Alert
resource "azurerm_monitor_activity_log_alert" "resource_deletion" {
  name                = "${var.project_name}-resource-deletion-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when resources are deleted from the subscription"

  criteria {
    category = "Administrative"
    operation_name = "Microsoft.Resources/subscriptions/resourceGroups/providers/resources/delete"
    level = "Informational"
  }

  action {
    action_group_id = azurerm_monitor_action_group.team_alerts.id
    
    webhook_properties = {
      "alert_type" = "resource_deletion"
      "team_notification" = "true"
      "severity" = "high"
    }
  }

  tags = var.tags
}

# High-Cost VM Creation Alert
resource "azurerm_monitor_activity_log_alert" "vm_creation" {
  name                = "${var.project_name}-vm-creation-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when Virtual Machines are created (potentially expensive)"

  criteria {
    category = "Administrative"
    operation_name = "Microsoft.Compute/virtualMachines/write"
    level = "Informational"
  }

  action {
    action_group_id = azurerm_monitor_action_group.team_alerts.id
    
    webhook_properties = {
      "alert_type" = "high_cost_resource"
      "resource_type" = "virtual_machine"
      "cost_impact" = "high"
    }
  }

  tags = var.tags
}

# High-Cost Databricks Creation Alert
resource "azurerm_monitor_activity_log_alert" "databricks_creation" {
  name                = "${var.project_name}-databricks-creation-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when Databricks workspaces are created (potentially expensive)"

  criteria {
    category = "Administrative"
    operation_name = "Microsoft.Databricks/workspaces/write"
    level = "Informational"
  }

  action {
    action_group_id = azurerm_monitor_action_group.team_alerts.id
    
    webhook_properties = {
      "alert_type" = "high_cost_resource"
      "resource_type" = "databricks"
      "cost_impact" = "high"
    }
  }

  tags = var.tags
}

# =============================================================================
# MONTHLY COST SUMMARY ALERT
# =============================================================================

# Monthly cost summary - triggered on 1st of each month
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "monthly_cost_summary" {
  name                = "${var.project_name}-monthly-cost-summary"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "P1D"     # Daily check
  window_duration     = "P2D"     # Look at past 2 days (maximum allowed)
  scopes             = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  severity           = 3  # Informational
  
  criteria {
    query                   = <<-QUERY
      Usage
      | where TimeGenerated >= ago(2d)
      | where IsBillable == true
      | extend ResourceGroup = tostring(split(ResourceUri, "/")[4])
      | where ResourceGroup == "${var.resource_group_name}"
      | summarize 
          RecentCost = sum(Quantity * UnitPrice),
          ResourceCount = dcount(ResourceUri),
          TopResources = make_list(pack("resource", Resource, "cost", Quantity * UnitPrice), 5)
      | extend 
          DailyAverage = RecentCost / 2,
          ProjectedMonthlyCost = DailyAverage * 30,
          BudgetUsagePercent = round((ProjectedMonthlyCost / ${var.monthly_budget_limit}.0) * 100, 2)
      | where dayofmonth(now()) == 1  # Only trigger on 1st of month
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
  description            = "Monthly cost summary report for ${length(var.team_email_addresses)}-member team ($${var.monthly_budget_limit} budget)"
  display_name          = "Monthly Cost Summary Report"
  
  action {
    action_groups = [azurerm_monitor_action_group.team_alerts.id]
    
    custom_properties = {
      "alert_type" = "monthly_summary"
      "report_type" = "cost_analysis"
      "team_size" = tostring(length(var.team_email_addresses))
    }
  }

  tags = var.tags
}

# =============================================================================
# RESOURCE HEALTH AND GOVERNANCE
# =============================================================================

# Resource Health Alert for critical resources
resource "azurerm_monitor_activity_log_alert" "resource_health" {
  name                = "${var.project_name}-resource-health-alert"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when resources become unhealthy or unavailable"

  criteria {
    category = "ResourceHealth"
    
    resource_health {
      current = ["Unavailable", "Degraded"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.team_alerts.id
    
    webhook_properties = {
      "alert_type" = "resource_health"
      "impact" = "service_availability"
    }
  }

  tags = var.tags
}

# Unusual Activity Alert - Multiple resource operations
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "unusual_activity" {
  name                = "${var.project_name}-unusual-activity-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  evaluation_frequency = "PT1H"    # Hourly check
  window_duration     = "PT1H"    # Look at past hour
  scopes             = [azurerm_log_analytics_workspace.cost_monitoring.id]
  severity           = 2
  
  criteria {
    query                   = <<-QUERY
      AzureActivity
      | where TimeGenerated >= ago(1h)
      | where ActivityStatusValue == "Success"
      | where OperationNameValue contains "write" or OperationNameValue contains "delete"
      | summarize 
          OperationCount = count(),
          UniqueCallers = dcount(Caller),
          Operations = make_set(OperationNameValue)
      | where OperationCount > 10 or UniqueCallers > 3
    QUERY
    time_aggregation_method = "Count"
    threshold              = 0
    operator               = "GreaterThan"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  auto_mitigation_enabled = false  # Manual review needed
  description            = "Unusual number of resource operations detected - possible unauthorized activity"
  display_name          = "Unusual Resource Activity Alert"
  
  action {
    action_groups = [azurerm_monitor_action_group.team_alerts.id]
    
    custom_properties = {
      "alert_type" = "security"
      "requires_review" = "true"
    }
  }

  tags = var.tags
}

# =============================================================================
# DIAGNOSTIC SETTINGS FOR COST MONITORING
# =============================================================================

# Activity Log diagnostic settings to capture all subscription activities
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "${var.project_name}-activity-log-diagnostics"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cost_monitoring.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}