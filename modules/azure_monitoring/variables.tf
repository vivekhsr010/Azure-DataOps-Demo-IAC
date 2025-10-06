variable "log_analytics_name" {
  description = "The name of the Log Analytics workspace"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "log_analytics_sku" {
  description = "The SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "app_insights_name" {
  description = "The name of the Application Insights component"
  type        = string
}

variable "storage_account_id" {
  description = "The ID of the storage account for diagnostics"
  type        = string
  default     = null
}

variable "keyvault_id" {
  description = "The ID of the Key Vault for diagnostics"
  type        = string
  default     = null
}

variable "enable_alerts" {
  description = "Whether to enable monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}