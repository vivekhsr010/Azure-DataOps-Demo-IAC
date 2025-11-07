# Azure Subscription Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string

  validation {
    condition     = can(regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid GUID format (e.g., 12345678-1234-1234-1234-123456789012)."
  }
}

//resource group variables are in modules/resource_group/variables.tf
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string

  validation {
    condition     = length(var.resource_group_name) >= 3 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 3 and 90 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.resource_group_name))
    error_message = "Resource group name can only contain alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus",
      "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope",
      "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "uksouth", "ukwest",
      "southeastasia", "eastasia", "australiaeast", "australiasoutheast", "centralindia", "southindia",
      "japaneast", "japanwest", "koreacentral", "southafricanorth"
    ], lower(var.location))
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "The environment (dev, test, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod."
  }
}

variable "project_name" {
  description = "The name of the project for resource naming"
  type        = string
  default     = "analytics"

  validation {
    condition     = length(var.project_name) >= 2 && length(var.project_name) <= 20
    error_message = "Project name must be between 2 and 20 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
//storage account variables are in modules/azure_datalake_storage/variables.tf
variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name can only contain lowercase letters and numbers."
  }
}
// Databricks variables are in modules/azure_databricks/variables.tf
variable "workspace_name" {
  description = "The name of the Databricks workspace"
  type        = string
}
variable "sku" {
  description = "The SKU of the Databricks workspace"
  type        = string
  default     = "standard"
}
variable "managed_resource_group_name" {
  description = "The name of the managed resource group for Databricks"
  type        = string
}
variable "cluster_name" {
  description = "The name of the Databricks cluster"
  type        = string
}
variable "spark_version" {
  description = "The Spark version for the Databricks cluster"
  type        = string
}
variable "node_type_id" {
  description = "The node type ID for the Databricks cluster"
  type        = string
}
variable "autotermination_minutes" {
  description = "The auto-termination time in minutes for the Databricks cluster"
  type        = number
  default     = 20
}
variable "num_workers" {
  description = "The number of workers for the Databricks cluster"
  type        = number
  default     = 0
}

# Key Vault Variables
variable "keyvault_name" {
  description = "The name of the Key Vault"
  type        = string
}

variable "keyvault_sku_name" {
  description = "The SKU name of the Key Vault"
  type        = string
  default     = "standard"
}

# Service Principal will be managed manually

variable "secret_scope_name" {
  description = "The name of the Databricks secret scope"
  type        = string
  default     = "keyvault-scope"
}

# Cost & Resource Monitoring Variables
variable "enable_cost_monitoring" {
  description = "Whether to enable cost and resource monitoring"
  type        = bool
  default     = true
}

variable "team_email_addresses" {
  description = "List of email addresses for team members (8 members max)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.team_email_addresses) <= 8 && length(var.team_email_addresses) > 0
    error_message = "Team must have between 1 and 8 email addresses."
  }

  validation {
    condition = alltrue([
      for email in var.team_email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD for the team"
  type        = number
  default     = 250

  validation {
    condition     = var.monthly_budget_limit > 0 && var.monthly_budget_limit <= 10000
    error_message = "Monthly budget must be between $1 and $10,000."
  }
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook URL for notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.teams_webhook_url == "" || can(regex("^https://[a-zA-Z0-9.-]+\\.webhook\\.office\\.com/", var.teams_webhook_url))
    error_message = "Teams webhook URL must be empty or a valid Microsoft Teams webhook URL (https://*.webhook.office.com/)."
  }
}

variable "teams_channel_name" {
  description = "Microsoft Teams channel name for notifications (optional, used in alert messages)"
  type        = string
  default     = "Azure Alerts"
}

variable "use_logic_app_for_teams" {
  description = "Whether to use Logic App for Teams integration (recommended) or direct webhook"
  type        = bool
  default     = true
}

variable "no_public_ip" {
  description = "Whether to disable public IP addresses for Databricks compute resources (recommended for security)"
  type        = bool
  default     = true
}

variable "deploy_databricks_cluster" {
  description = "Whether to deploy Databricks clusters and resources (Phase 2). Set to false for workspace-only deployment (Phase 1)"
  type        = bool
  default     = false
}

# ===================================
# Azure Data Factory Configuration
# ===================================

variable "enable_data_factory" {
  description = "Whether to deploy Azure Data Factory with essential linked services (ADLS, Key Vault, Databricks)"
  type        = bool
  default     = false
}

variable "adf_enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for Data Factory monitoring"
  type        = bool
  default     = true
}

variable "single_node_cluster" {
  description = "Whether to create a single node cluster (equivalent to UI checkbox). When true, sets num_workers to 0 and configures single node spark settings"
  type        = bool
  default     = true
}