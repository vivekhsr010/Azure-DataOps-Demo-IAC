# Azure Analytics Infrastructure with Terraform

This Terraform configuration creates a comprehensive, enterprise-grade analytics infrastructure on Azure featuring:
- **🏗️ Secure Remote State Backend** with automated setup and health monitoring
- **📊 Azure Data Lake Storage** with hierarchical namespace and enterprise security
- **⚡ Azure Databricks** with phase-based deployment (workspace + clusters)
- **🔐 Azure Key Vault** for secure credential management with comprehensive permissions
- **🎯 Single Node Clusters** with UI-equivalent configuration options
- **🛡️ No Public IP** security configuration for enhanced isolation
- **📈 Monitoring & Logging** with Azure Monitor, Application Insights, and alerting
- **🔧 Phase-Based Deployment** for reliable Databricks workspace and cluster setup

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Data Lake      │    │   Key Vault     │    │   Databricks    │
│  Storage        │◄──►│ (Full Perms)    │◄──►│   Workspace     │
│  (GRS)          │    │                 │    │  (Premium)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Single Node   │    │  Log Analytics  │    │   Application   │
│   Clusters      │    │  Workspace      │    │   Insights      │
│ (No Public IP)  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🚀 Phase-Based Deployment Strategy

**Phase 1: Core Infrastructure**
- Resource Group, Storage Account, Key Vault
- Databricks Workspace (without clusters)
- Monitoring and Logging setup

**Phase 2: Databricks Resources** 
- Single Node Clusters with security configuration
- Key Vault Secret Scopes
- Custom Spark configurations

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.9.0 installed
3. **Azure subscription** with appropriate permissions

### Setup Steps

1. **Clone and configure**:
   ```bash
   git clone <your-repo>
   cd azure_terraform
   ```

2. **Update configuration**:
   ```bash
   # Copy and edit the variables file
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   # - Update monitoring_email with your email address
   # - Modify resource names as needed
   ```

3. **Setup secure backend** (automated):
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   
   # Create secure state backend (one-time setup)
   ./scripts/setup-backend.sh
   
   # Verify backend health
   ./scripts/check-backend-status.sh
   ```

4. **Phase-based deployment**:
   ```bash
   # Initialize Terraform with remote backend
   terraform init -reconfigure
   
   # Phase 1: Deploy core infrastructure (workspace only)
   # Ensure deploy_databricks_cluster = false in terraform.tfvars
   terraform plan
   terraform apply
   
   # Phase 2: Deploy Databricks clusters and resources  
   # Set deploy_databricks_cluster = true in terraform.tfvars
   terraform plan
   terraform apply
   ```

## 📁 Project Structure

```
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables with validation
├── outputs.tf                # Output values
├── locals.tf                 # Local values and naming
├── data.tf                   # Data sources
├── provider.tf               # Provider configuration
├── backend.tf                # Remote state backend
├── backend.hcl               # Backend configuration file
├── terraform.tfvars          # Variable values
├── modules/
│   ├── azure_resource_group/     # Resource group module
│   ├── azure_datalake_storage/   # Data lake storage module  
│   ├── azure_databricks_workspace/  # Phase 1: Databricks workspace only
│   ├── azure_databricks_cluster/    # Phase 2: Databricks clusters & resources
│   ├── azure_keyvault/           # Key Vault with full permissions
│   └── azure_monitoring/         # Monitoring and logging module
└── scripts/
    ├── setup-backend.sh       # Automated backend creation with security
    ├── check-backend-status.sh # Backend health monitoring
    └── backup-state.sh        # State file backup utility
```

## 🏗️ Backend Management

### Automated Setup
The project includes automated scripts for secure backend management:

```bash
# Create backend infrastructure with enterprise security
./scripts/setup-backend.sh

# Monitor backend health and access
./scripts/check-backend-status.sh

# Backup state file
./scripts/backup-state.sh
```

### Backend Features
- **🔒 Enterprise Security**: GRS replication, versioning, soft delete (30 days)
- **🔐 Access Control**: Role-based access with Storage Blob Data Owner permissions  
- **📊 Health Monitoring**: Automated checks for resources, permissions, and state
- **🔄 State Versioning**: Automatic versioning with 30-day retention
- **💾 Backup Strategy**: Container delete retention (7 days) with manual backup scripts

### Backend Configuration
```hcl
# Current backend configuration (backend.tf)
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterrastate43879"  # Auto-generated unique name
    container_name       = "tfstate"
    key                  = "analytics/terraform.tfstate"
  }
}
```

## 🔐 Security Features

### Network Security
- **No Public IP** configuration for Databricks compute nodes
- **Private network isolation** with VNet integration
- **Enhanced security posture** for enterprise compliance

### Key Vault Security  
- **Comprehensive permissions** for keys, secrets, and certificates
- **Full certificate authority management** capabilities
- **Rotation policies** and backup/restore operations
- **Audit logging** for all Key Vault operations

### Access Control
- **Manual Service Principal** management for production security
- **Storage Contributor** role on Data Lake
- **Databricks secret scope** backed by Key Vault
- **Role-based access control** across all resources

### Databricks Security
- **Single Node clusters** with custom Spark configurations
- **No Public IP** enforcement for compute isolation  
- **Premium workspace** with advanced security features
- **Secret scope integration** with Key Vault

## 📊 Monitoring & Alerting

### Log Analytics Workspace
- Centralized logging for all resources
- 30-day retention (configurable)
- Integration with Azure Monitor

### Alerts Configured
- Service Principal password expiry warnings
- Key Vault access anomalies
- Storage account unauthorized access

## 🔧 Configuration Options

### Key Variables in `terraform.tfvars`:

```hcl
# Basic Configuration
resource_group_name  = "rg-terraform-datalake"
location            = "eastus"
environment         = "dev"
project_name        = "analytics"

# Storage Configuration  
storage_account_name = "stterraformdatalake2025"

# Databricks Configuration
workspace_name              = "dbw-terraform-analytics"
sku                        = "premium"        # Premium tier for enterprise features
cluster_name               = "analytics-single-node"
spark_version              = "16.4.x-scala2.13"
node_type_id              = "Standard_F4"
num_workers               = 0                # Managed by single_node_cluster setting
no_public_ip              = true             # Enhanced security - no public IPs

# Security Configuration
keyvault_name             = "kv-terraform-secrets"

# Phase Control
deploy_databricks_cluster = false           # Phase 1: false, Phase 2: true
single_node_cluster      = true            # UI checkbox equivalent

# Monitoring Configuration
enable_monitoring_alerts = true
monitoring_email        = "your-email@company.com"
```

## 🎯 Usage Examples

### Accessing Data Lake from Databricks

The cluster is pre-configured with service principal authentication:

```python
# Read data directly from Data Lake
df = spark.read.parquet("abfss://container@yourstorageaccount.dfs.core.windows.net/data/")

# Write data to Data Lake
df.write.mode("overwrite").parquet("abfss://container@yourstorageaccount.dfs.core.windows.net/output/")
```

### Managing Secrets

```python
# Access secrets from Databricks
client_id = dbutils.secrets.get(scope="keyvault-secrets", key="sp-client-id")
tenant_id = dbutils.secrets.get(scope="keyvault-secrets", key="sp-tenant-id")
```

## 🎯 Single Node Cluster Configuration

### UI Checkbox Equivalent
The `single_node_cluster` variable replicates the Databricks UI "Single Node" checkbox:

```hcl
# terraform.tfvars
single_node_cluster = true   # ✅ Like checking UI checkbox
```

### Automatic Configuration
When `single_node_cluster = true`:
- **Workers**: Automatically sets `num_workers = 0`
- **Spark Config**: Adds single node optimizations:
  - `spark.databricks.cluster.profile = "singleNode"`
  - `spark.master = "local[*]"`
- **Tags**: Adds `ResourceClass = "SingleNode"` for identification
- **Driver**: Uses specified node type for single node operation

### Multi-Node Alternative
```hcl
single_node_cluster = false  # For multi-node clusters
num_workers = 2             # Number of worker nodes
```

## 🛠️ Troubleshooting

### Backend Issues

1. **Check Backend Health**:
   ```bash
   ./scripts/check-backend-status.sh
   ```

2. **Recreate Backend** (if needed):
   ```bash
   # Remove existing backend (WARNING: will lose state)
   az group delete --name rg-terraform-state --yes
   
   # Recreate with automation
   ./scripts/setup-backend.sh
   ```

3. **State Access Issues**:
   ```bash
   # Check your permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv) --scope /subscriptions/$(az account show --query id -o tsv)
   
   # Re-initialize if needed
   terraform init -reconfigure
   ```

### Infrastructure Issues

1. **Phase-Based Deployment Issues**:
   ```bash
   # Phase 1: Deploy workspace first
   # Set deploy_databricks_cluster = false
   terraform apply
   
   # Phase 2: Deploy clusters after workspace is ready
   # Set deploy_databricks_cluster = true  
   terraform apply
   ```

2. **Databricks Provider Authentication**:
   ```bash
   # Ensure workspace exists before cluster deployment
   terraform refresh
   terraform state show module.databricks_workspace.azurerm_databricks_workspace.this_workspace
   ```

3. **Key Vault Access**:
   ```bash
   az keyvault set-policy --name <keyvault-name> --object-id <user-object-id> \
     --key-permissions get list create update import delete recover backup restore \
     --secret-permissions get list set delete recover backup restore \
     --certificate-permissions get list create update import delete recover backup restore
   ```

## 🎮 Useful Commands

### Backend Management
```bash
# Check backend status and health
./scripts/check-backend-status.sh

# View current Terraform state
terraform state list
terraform state show <resource_name>

# Backup state file manually
./scripts/backup-state.sh
```

### Infrastructure Management
```bash
# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current infrastructure
terraform show

# Refresh state
terraform refresh

# Destroy infrastructure (careful!)
terraform destroy
```

### Debugging and Logs
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan

# Check Azure resources directly
az resource list --resource-group rg-terraform-analytics --output table

# Monitor Key Vault operations
az monitor activity-log list --resource-group rg-terraform-analytics
```

## 📋 Project Status

✅ **Completed Features**:
- Secure remote state backend with automated setup
- Phase-based deployment architecture for reliable Databricks setup
- Azure Data Lake Storage with enterprise security (GRS replication)
- Azure Key Vault with comprehensive permissions (keys, secrets, certificates)
- Databricks workspace with Premium SKU and no public IP configuration
- Single node cluster support with UI-equivalent checkbox functionality
- Comprehensive monitoring and alerting setup
- Automated backup and health check scripts

🔄 **Ready for Deployment**:
- Phase 1: Core infrastructure (workspace, storage, key vault, monitoring)
- Phase 2: Databricks clusters with single node configuration
- All modules tested and validated with proper provider configurations
- Security policies and access controls in place
- Network isolation with no public IP enforcement

## 🚨 Important Notes

- **Phase Deployment**: Use phase-based approach - workspace first, then clusters
- **State Storage**: Remote state backend is configured with GRS replication and versioning  
- **Network Security**: No public IP configuration enhances security but requires VNet setup
- **Single Node**: UI checkbox equivalent with automatic Spark optimizations
- **Key Vault**: Full permissions configured for enterprise certificate management
- **Resource Naming**: Storage accounts and Key Vault use unique timestamp-based naming
- **Monitoring**: Production-ready alerts configured for critical events
- **Security**: Enterprise-grade security with network isolation and comprehensive access control

## 📧 Support & Resources

### Getting Help
1. **Check backend health**: `./scripts/check-backend-status.sh`
2. **Review troubleshooting section** above
3. **Check Azure Monitor logs** for detailed error information
4. **Validate configuration**: `terraform validate && terraform plan`

### Useful Resources
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Databricks Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Service Principal Password Rotation](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)

### Project Metadata
- **Terraform Version**: >= 1.9.0
- **Azure Provider**: ~> 4.8.0
- **Last Updated**: October 6, 2025
- **Backend Status**: ✅ Configured and Verified
- **Security Level**: 🔒 Enterprise Grade

---
⚡ **Ready for deployment** | 🔐 **Enterprise security enabled** | 📊 **Monitoring configured**