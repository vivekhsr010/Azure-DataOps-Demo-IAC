# =============================================================================
# AZURE LOGIC APPS MODULE
# =============================================================================
# Generic Logic Apps module for workflow automation and integration
# Supports HTTP triggers, webhook receivers, and custom actions
# =============================================================================

# Logic App Workflow
resource "azurerm_logic_app_workflow" "this" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# HTTP Request Trigger
resource "azurerm_logic_app_trigger_http_request" "this" {
  count        = var.enable_http_trigger ? 1 : 0
  name         = var.trigger_name
  logic_app_id = azurerm_logic_app_workflow.this.id

  schema = var.trigger_schema
}

# HTTP Action for webhook calls
resource "azurerm_logic_app_action_http" "this" {
  count        = var.enable_http_action ? 1 : 0
  name         = var.action_name
  logic_app_id = azurerm_logic_app_workflow.this.id

  method = var.http_method
  uri    = var.webhook_uri

  headers = var.http_headers
  body    = var.http_body

  depends_on = [azurerm_logic_app_trigger_http_request.this]
}