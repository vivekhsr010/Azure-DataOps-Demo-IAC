module "resource_group" {
  source              = "./modules/azure_resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.common_tags
}
module "datalake_storage" {
  depends_on           = [module.resource_group]
  source               = "./modules/azure_datalake_storage"
  storage_account_name = var.storage_account_name
  resource_group_name  = module.resource_group.resource_group_name
  location             = var.location
  tags                 = local.common_tags
}

module "azure_keyvault" {
  depends_on          = [module.resource_group, random_integer.kv_suffix]
  source              = "./modules/azure_keyvault"
  keyvault_name       = local.resource_names.keyvault
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  sku_name            = var.keyvault_sku_name
  tags                = local.common_tags
}

# Phase 1: Deploy Databricks workspace
module "databricks_workspace" {
  depends_on                  = [module.azure_keyvault]
  source                      = "./modules/azure_databricks_workspace"
  workspace_name              = var.workspace_name
  resource_group_name         = module.resource_group.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = var.managed_resource_group_name
  no_public_ip                = var.no_public_ip
  tags                        = local.common_tags
}

# Phase 2: Deploy Databricks clusters (conditional)
module "databricks_cluster" {
  count                   = var.deploy_databricks_cluster ? 1 : 0
  depends_on              = [module.databricks_workspace]
  source                  = "./modules/azure_databricks_cluster"
  cluster_name            = var.cluster_name
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  autotermination_minutes = var.autotermination_minutes
  num_workers             = var.num_workers
  single_node             = var.single_node_cluster
  keyvault_id             = module.azure_keyvault.keyvault_id
  keyvault_uri            = module.azure_keyvault.keyvault_uri
  secret_scope_name       = var.secret_scope_name
  custom_tags             = local.common_tags

  providers = {
    databricks = databricks.workspace
  }
}

module "monitoring" {
  depends_on          = [module.resource_group]
  source              = "./modules/azure_monitoring"
  log_analytics_name  = "log-${local.naming_prefix}"
  app_insights_name   = "appi-${local.naming_prefix}"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  storage_account_id     = module.datalake_storage.storage_account_id
  keyvault_id           = module.azure_keyvault.keyvault_id
  databricks_workspace_id = module.databricks_workspace.workspace_id
  enable_alerts         = var.enable_monitoring_alerts
  alert_email           = var.monitoring_email
  tags                  = local.common_tags
}