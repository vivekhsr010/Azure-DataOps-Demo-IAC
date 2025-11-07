# Azure Data Factory Module Variables - Minimal Configuration
# Essential variables for ADF with Databricks, ADLS, and Key Vault integration

# Basic Configuration
variable "data_factory_name" {
  description = "Name of the Azure Data Factory instance"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.data_factory_name))
    error_message = "Data Factory name must be 3-63 characters long, start and end with alphanumeric characters, and contain only letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region where the Data Factory will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Data Factory will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Azure Data Lake Storage Gen2 Linked Service
variable "datalake_url" {
  description = "URL of the Data Lake Storage Gen2 account (e.g., https://storageaccount.dfs.core.windows.net/)"
  type        = string
}

# Key Vault Linked Service
variable "key_vault_id" {
  description = "ID of the Key Vault to link (e.g., /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/...)"
  type        = string
}

# Databricks Linked Service
variable "databricks_workspace_url" {
  description = "URL of the Databricks workspace (e.g., https://adb-123456789.10.azuredatabricks.net/)"
  type        = string
}

variable "databricks_workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  type        = string
}

variable "databricks_cluster_id" {
  description = "ID of the Databricks cluster to use (optional - can use job clusters instead)"
  type        = string
  default     = null
}

# Optional: Monitoring Configuration
variable "enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for Data Factory monitoring"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings (required if enable_diagnostic_settings is true)"
  type        = string
  default     = null
}