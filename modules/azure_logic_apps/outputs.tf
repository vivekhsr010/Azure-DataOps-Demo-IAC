# =============================================================================
# AZURE LOGIC APPS MODULE - OUTPUTS
# =============================================================================

output "logic_app_id" {
  description = "ID of the Logic App workflow"
  value       = azurerm_logic_app_workflow.this.id
}

output "logic_app_name" {
  description = "Name of the Logic App workflow"
  value       = azurerm_logic_app_workflow.this.name
}

output "callback_url" {
  description = "Callback URL for the HTTP trigger"
  value       = var.enable_http_trigger ? azurerm_logic_app_trigger_http_request.this[0].callback_url : null
  sensitive   = true
}

output "access_endpoint" {
  description = "Access endpoint for the Logic App"
  value       = azurerm_logic_app_workflow.this.access_endpoint
  sensitive   = true
}