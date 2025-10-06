output "cluster_id" {
  description = "The ID of the Databricks cluster"
  value       = databricks_cluster.this_cluster.id
}

output "cluster_name" {
  description = "The name of the Databricks cluster"
  value       = databricks_cluster.this_cluster.cluster_name
}

output "secret_scope_name" {
  description = "The name of the secret scope (if created)"
  value       = var.keyvault_id != null ? databricks_secret_scope.keyvault[0].name : null
}