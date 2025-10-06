variable "keyvault_name" {
  description = "The name of the Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where the Key Vault will be created"
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the Key Vault"
  type        = string
  default     = "standard"
}

variable "enabled_for_disk_encryption" {
  description = "Whether Azure Disk Encryption is permitted to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Whether Azure Resource Manager is permitted to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled for this Key Vault"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  type        = number
  default     = 7
}

variable "network_acls_default_action" {
  description = "The default action to use when no rules match from ip_rules / virtual_network_subnet_ids"
  type        = string
  default     = "Allow"
}

variable "network_acls_bypass" {
  description = "Specifies which traffic can bypass the network rules"
  type        = string
  default     = "AzureServices"
}

variable "create_sample_secrets" {
  description = "Whether to create sample secrets in the Key Vault"
  type        = bool
  default     = true
}

# Service principal variables removed - will be managed manually

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}