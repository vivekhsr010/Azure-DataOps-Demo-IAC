# Azure Configuration
resource_group_name  = "rg-terraform-datalake"
location             = "eastus"
storage_account_name = "stterraformdatalake2025"
subscription_id      = "value"

# Databricks Configuration
workspace_name              = "dbw-terraform-analytics"
sku                         = "premium"
managed_resource_group_name = "rg-databricks-managed"
cluster_name                = "analytics-single-node"
spark_version               = "16.4.x-scala2.13"
node_type_id                = "Standard_F4"
autotermination_minutes     = 20
num_workers                 = 0
no_public_ip                = false

# Key Vault Configuration
keyvault_name     = "kv-terraform-secrets"
keyvault_sku_name = "standard"

# Databricks Configuration
secret_scope_name = "keyvault-secrets"

# Cost & Resource Monitoring Configuration (8-Member Team)
enable_cost_monitoring = true
team_email_addresses = [
  "team-lead@example.com",
  "developer1@example.com", 
  "developer2@example.com",
  "developer3@example.com",
  "data-engineer1@example.com",
  "data-engineer2@example.com",
  "analyst1@example.com",
  "analyst2@example.com"
]
monthly_budget_limit = 250  # $250 monthly budget for 8-member team
webhook_url         = ""    # Optional: Add Slack/Teams webhook for notifications

# Environment Configuration
environment  = "dev"
project_name = "analytics"

# Deployment Control
deploy_databricks_cluster = true   # Set to true for Phase 2 deployment
single_node_cluster      = true   # Single node cluster (UI checkbox equivalent)

tags = {
  environment = "dev"
  project     = "terraform-azure"
  owner       = "vivek"
}
