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
  depends_on              = [module.databricks_workspace, module.azure_keyvault]
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
  create_secret_scope     = true
  custom_tags             = local.common_tags

  providers = {
    databricks = databricks
  }
}

# Azure Data Factory - Minimal Setup
module "data_factory" {
  count               = var.enable_data_factory ? 1 : 0
  depends_on          = [module.resource_group, module.datalake_storage, module.azure_keyvault, module.databricks_workspace]
  source              = "./modules/azure_data_factory"
  data_factory_name   = local.resource_names.data_factory
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  
  # Essential Linked Services
  datalake_url                = module.datalake_storage.primary_dfs_endpoint
  key_vault_id                = module.azure_keyvault.keyvault_id
  databricks_workspace_url    = module.databricks_workspace.workspace_url
  databricks_workspace_id     = module.databricks_workspace.workspace_id
  databricks_cluster_id       = var.deploy_databricks_cluster ? module.databricks_cluster[0].cluster_id : null
  
  # Optional Monitoring
  enable_diagnostic_settings  = var.adf_enable_diagnostic_settings
  log_analytics_workspace_id  = var.enable_cost_monitoring ? module.cost_monitoring[0].log_analytics_workspace_id : null
  
  tags = local.common_tags
}

# Cost & Resource Monitoring
module "cost_monitoring" {
  count               = var.enable_cost_monitoring ? 1 : 0
  depends_on          = [module.resource_group]
  source              = "./modules/azure_monitoring"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  team_email_addresses = var.team_email_addresses
  monthly_budget_limit = var.monthly_budget_limit
  webhook_url         = var.webhook_url
  tags                = local.common_tags
}
