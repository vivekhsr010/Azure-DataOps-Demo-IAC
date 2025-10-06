variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}
variable "resource_group_name" {
  description = "The name of the resource group where the storage account will be created"
  type        = string
}
variable "location" {
  description = "The Azure region where the storage account will be created"
  type        = string
}
variable "tags" {
    description = "A map of tags to assign to the storage account"
  type        = map(string)
  default     = {}
}   