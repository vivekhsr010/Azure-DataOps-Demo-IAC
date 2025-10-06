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

variable "keyvault_id" {
  description = "The ID of the Key Vault for secret scope"
  type        = string
  default     = null
}

variable "keyvault_uri" {
  description = "The URI of the Key Vault for secret scope"
  type        = string
  default     = null
}

variable "secret_scope_name" {
  description = "The name of the Databricks secret scope"
  type        = string
  default     = "keyvault-scope"
}

variable "single_node" {
  description = "Whether to create a single node cluster (equivalent to UI checkbox)"
  type        = bool
  default     = true
}

variable "driver_node_type_id" {
  description = "The node type ID for the driver node (if different from worker nodes)"
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "Custom tags for the Databricks cluster"
  type        = map(string)
  default     = {}
}