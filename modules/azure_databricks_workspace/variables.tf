variable "workspace_name" {
  description = "The name of the Databricks workspace"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "sku" {
  description = "The SKU of the Databricks workspace"
  type        = string
  default     = "premium"
}

variable "managed_resource_group_name" {
  description = "The name of the managed resource group for Databricks"
  type        = string
}

variable "no_public_ip" {
  description = "Whether to disable public IP addresses for compute resources"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}