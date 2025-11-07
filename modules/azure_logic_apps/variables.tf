# =============================================================================
# AZURE LOGIC APPS MODULE - VARIABLES
# =============================================================================

variable "logic_app_name" {
  description = "Name of the Logic App workflow"
  type        = string
}

variable "location" {
  description = "Azure region where the Logic App will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Logic App will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# HTTP Trigger Configuration
variable "enable_http_trigger" {
  description = "Whether to enable HTTP request trigger"
  type        = bool
  default     = true
}

variable "trigger_name" {
  description = "Name of the HTTP trigger"
  type        = string
  default     = "HTTPTrigger"
}

variable "trigger_schema" {
  description = "JSON schema for the HTTP trigger"
  type        = string
  default     = "{}"
}

# HTTP Action Configuration
variable "enable_http_action" {
  description = "Whether to enable HTTP action"
  type        = bool
  default     = true
}

variable "action_name" {
  description = "Name of the HTTP action"
  type        = string
  default     = "HTTPAction"
}

variable "http_method" {
  description = "HTTP method for the action"
  type        = string
  default     = "POST"

  validation {
    condition     = contains(["GET", "POST", "PUT", "PATCH", "DELETE"], var.http_method)
    error_message = "HTTP method must be one of: GET, POST, PUT, PATCH, DELETE."
  }
}

variable "webhook_uri" {
  description = "URI for the webhook endpoint"
  type        = string
}

variable "http_headers" {
  description = "Headers for the HTTP request"
  type        = map(string)
  default = {
    "Content-Type" = "application/json"
  }
}

variable "http_body" {
  description = "Body content for the HTTP request"
  type        = string
}