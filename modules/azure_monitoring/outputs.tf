# =============================================================================
# AZURE COST & RESOURCE MONITORING MODULE - OUTPUTS
# =============================================================================

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.name
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.cost_monitoring.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.cost_monitoring.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.cost_monitoring.connection_string
  sensitive   = true
}

output "action_group_id" {
  description = "ID of the monitoring action group"
  value       = azurerm_monitor_action_group.team_alerts.id
}

output "monthly_budget_id" {
  description = "ID of the monthly budget"
  value       = azurerm_consumption_budget_subscription.monthly_budget.id
}

output "teams_logic_app_id" {
  description = "ID of the Teams Logic App workflow"
  value       = var.teams_webhook_url != "" ? module.teams_logic_app[0].logic_app_id : null
}

output "teams_logic_app_callback_url" {
  description = "Callback URL for the Teams Logic App trigger"
  value       = var.teams_webhook_url != "" ? module.teams_logic_app[0].callback_url : null
  sensitive   = true
}

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    project_name            = var.project_name
    monthly_budget          = var.monthly_budget_limit
    team_members            = length(var.team_email_addresses)
    cost_alerts_enabled     = var.enable_cost_alerts
    resource_alerts_enabled = var.enable_resource_alerts
    workspace_name          = azurerm_log_analytics_workspace.cost_monitoring.name
    teams_integration       = var.teams_webhook_url != ""
    teams_via_logic_app     = var.teams_webhook_url != "" && var.use_logic_app_for_teams
    teams_channel           = var.teams_channel_name
  }
}