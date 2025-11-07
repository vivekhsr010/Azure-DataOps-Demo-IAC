terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      # Version managed centrally in root provider.tf
    }
  }
}

resource "databricks_cluster" "this_cluster" {
  cluster_name            = var.cluster_name
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  autotermination_minutes = var.autotermination_minutes
  
  # Single node configuration (equivalent to UI checkbox)
  num_workers = var.single_node ? 0 : var.num_workers
  
  # Single node specific Spark configuration
  spark_conf = var.single_node ? {
    "spark.databricks.cluster.profile" = "singleNode"
    "spark.master"                     = "local[*]"
  } : {}
  
  # Custom tags for single node identification  
  custom_tags = merge(
    var.single_node ? { "ResourceClass" = "SingleNode" } : {},
    var.custom_tags
  )
  
  # Driver node configuration
  driver_node_type_id = var.driver_node_type_id != null ? var.driver_node_type_id : var.node_type_id
}

# Optional: Secret scope for Key Vault integration
resource "databricks_secret_scope" "keyvault" {
  count = var.create_secret_scope ? 1 : 0
  name  = var.secret_scope_name

  keyvault_metadata {
    resource_id = var.keyvault_id
    dns_name    = var.keyvault_uri
  }
}