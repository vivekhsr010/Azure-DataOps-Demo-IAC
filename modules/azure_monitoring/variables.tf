# =============================================================================
# AZURE COST & RESOURCE MONITORING MODULE - VARIABLES
# =============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "team_email_addresses" {
  description = "List of email addresses for team members (8 members max)"
  type        = list(string)

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
  description = "Monthly budget limit in USD"
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

variable "enable_cost_alerts" {
  description = "Whether to enable cost monitoring alerts"
  type        = bool
  default     = true
}

variable "enable_resource_alerts" {
  description = "Whether to enable resource creation/deletion alerts"
  type        = bool
  default     = true
}

variable "daily_cost_threshold" {
  description = "Daily cost threshold in USD (default: 1/30 of monthly budget)"
  type        = number
  default     = null
}