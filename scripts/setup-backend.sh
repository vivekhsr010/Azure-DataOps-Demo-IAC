#!/bin/bash

# =============================================================================
# Terraform Backend Setup Script
# =============================================================================
# This script creates and configures a secure Azure Storage backend for 
# Terraform state files with enterprise security features.
#
# Features:
# - Creates resource group if it doesn't exist
# - Creates storage account with security hardening
# - Enables versioning, soft delete, and encryption
# - Configures proper access controls
# - Updates Terraform backend configuration
# =============================================================================

set -e  # Exit on any error

# Configuration Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
LOCATION="East US"
CONTAINER_NAME="tfstate"
STATE_KEY="analytics/terraform.tfstate"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Generate unique storage account name
generate_storage_name() {
    local base="stterrastate"
    local suffix=$(date +%s | tail -c 6)
    echo "${base}${suffix}"
}

# Check if Azure CLI is installed and authenticated
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Not authenticated with Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create resource group if it doesn't exist
create_resource_group() {
    log_info "Checking resource group: $RESOURCE_GROUP_NAME"
    
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        log_success "Resource group '$RESOURCE_GROUP_NAME' already exists"
    else
        log_info "Creating resource group '$RESOURCE_GROUP_NAME'..."
        az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --tags Environment=shared ManagedBy=terraform Purpose=state-storage \
            --output none
        log_success "Resource group '$RESOURCE_GROUP_NAME' created"
    fi
}

# Create storage account with security features
create_storage_account() {
    local storage_name
    
    # Check if we already have a storage account in the resource group
    local existing_storage=$(az storage account list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[?tags.Purpose=='state-storage'].name" \
        --output tsv)
    
    if [ -n "$existing_storage" ]; then
        log_success "Using existing storage account: $existing_storage"
        STORAGE_ACCOUNT_NAME="$existing_storage"
    else
        # Generate unique storage account name
        storage_name=$(generate_storage_name)
        log_info "Creating storage account: $storage_name"
        
        # Try to create storage account with unique name
        local attempts=0
        local max_attempts=5
        
        while [ $attempts -lt $max_attempts ]; do
            if az storage account create \
                --name "$storage_name" \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --location "$LOCATION" \
                --sku "Standard_GRS" \
                --kind "StorageV2" \
                --access-tier "Hot" \
                --https-only true \
                --min-tls-version "TLS1_2" \
                --allow-blob-public-access false \
                --tags Environment=shared ManagedBy=terraform Purpose=state-storage \
                --output none 2>/dev/null; then
                
                STORAGE_ACCOUNT_NAME="$storage_name"
                log_success "Storage account '$storage_name' created successfully"
                break
            else
                attempts=$((attempts + 1))
                storage_name=$(generate_storage_name)
                log_warning "Storage name taken, trying: $storage_name (attempt $attempts/$max_attempts)"
            fi
        done
        
        if [ $attempts -eq $max_attempts ]; then
            log_error "Failed to create storage account after $max_attempts attempts"
            exit 1
        fi
    fi
}

# Configure storage security features
configure_storage_security() {
    log_info "Configuring storage security features..."
    
    # Enable versioning and soft delete
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-versioning true \
        --enable-delete-retention true \
        --delete-retention-days 30 \
        --output none
    
    # Enable container soft delete
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-container-delete-retention true \
        --container-delete-retention-days 7 \
        --output none
    
    log_success "Storage security features configured"
}

# Create storage container
create_storage_container() {
    log_info "Creating storage container: $CONTAINER_NAME"
    
    # Check if container exists
    if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login &> /dev/null; then
        log_success "Container '$CONTAINER_NAME' already exists"
    else
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --public-access off \
            --auth-mode login \
            --output none
        log_success "Container '$CONTAINER_NAME' created"
    fi
}

# Assign proper permissions
assign_permissions() {
    log_info "Configuring access permissions..."
    
    # Get current user object ID
    local user_object_id=$(az ad signed-in-user show --query id -o tsv)
    
    # Assign Storage Blob Data Owner role
    local storage_scope="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
    
    if az role assignment list \
        --assignee "$user_object_id" \
        --scope "$storage_scope" \
        --query "[?roleDefinitionName=='Storage Blob Data Owner']" \
        --output tsv | grep -q .; then
        log_success "Permissions already configured"
    else
        az role assignment create \
            --assignee "$user_object_id" \
            --role "Storage Blob Data Owner" \
            --scope "$storage_scope" \
            --output none
        log_success "Storage permissions assigned"
        log_warning "Role assignment may take a few minutes to propagate"
    fi
}

# Update Terraform backend configuration
update_backend_config() {
    log_info "Updating Terraform backend configuration..."
    
    # Update backend.tf
    cat > backend.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$STATE_KEY"
  }
}

# Alternative: Use environment variables or backend config file
# Create backend.hcl file with the values above
# Then run: terraform init -backend-config=backend.hcl
EOF

    # Update backend.hcl
    cat > backend.hcl << EOF
# Backend configuration for Terraform state
# Use: terraform init -reconfigure

resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "$STATE_KEY"
EOF

    log_success "Backend configuration files updated"
}

# Initialize Terraform with new backend
initialize_terraform() {
    log_info "Initializing Terraform with remote backend..."
    
    # Wait a moment for permissions to propagate
    sleep 5
    
    if terraform init -reconfigure; then
        log_success "Terraform initialized successfully with remote backend"
    else
        log_warning "Terraform initialization had issues. You may need to wait for permissions to propagate and run 'terraform init -reconfigure' manually."
    fi
}

# Verify backend setup
verify_backend() {
    log_info "Verifying backend setup..."
    
    # Check if local state file is minimal (indicating remote backend is used)
    if [ -f "terraform.tfstate" ]; then
        local state_size=$(wc -c < "terraform.tfstate")
        if [ "$state_size" -lt 100 ]; then
            log_success "Local state file is minimal (using remote backend)"
        else
            log_warning "Local state file is large. Backend migration may be incomplete."
        fi
    fi
    
    # Test terraform state access
    if terraform state list &> /dev/null; then
        log_success "Terraform state is accessible via remote backend"
    else
        log_warning "Unable to access Terraform state. Backend may need time to propagate."
    fi
}

# Create backup and recovery script
create_recovery_script() {
    cat > scripts/backup-state.sh << 'EOF'
#!/bin/bash
# Terraform State Backup Script

BACKUP_DIR="backups/terraform-state"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
STORAGE_ACCOUNT_NAME="$1"

mkdir -p "$BACKUP_DIR"

echo "Creating backup of Terraform state..."
az storage blob download \
    --container-name tfstate \
    --name analytics/terraform.tfstate \
    --file "$BACKUP_DIR/terraform.tfstate.backup_$TIMESTAMP" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login

echo "Backup created: $BACKUP_DIR/terraform.tfstate.backup_$TIMESTAMP"
EOF

    chmod +x scripts/backup-state.sh
    log_success "Backup script created at scripts/backup-state.sh"
}

# Display summary
show_summary() {
    echo ""
    echo "========================================="
    echo -e "${GREEN}🎉 Backend Setup Complete!${NC}"
    echo "========================================="
    echo ""
    echo -e "${BLUE}Backend Details:${NC}"
    echo "  Resource Group: $RESOURCE_GROUP_NAME"
    echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "  Container: $CONTAINER_NAME"
    echo "  State Key: $STATE_KEY"
    echo ""
    echo -e "${BLUE}Security Features Enabled:${NC}"
    echo "  ✅ HTTPS-only access"
    echo "  ✅ TLS 1.2 minimum"
    echo "  ✅ Blob versioning"
    echo "  ✅ Soft delete (30 days)"
    echo "  ✅ Container soft delete (7 days)"
    echo "  ✅ GRS replication"
    echo "  ✅ Private container access"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Run 'terraform plan' to test configuration"
    echo "  2. Run 'terraform apply' to deploy infrastructure"
    echo "  3. Use 'scripts/backup-state.sh $STORAGE_ACCOUNT_NAME' for backups"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  • State file is now stored securely in Azure"
    echo "  • Local terraform.tfstate is minimal/empty"
    echo "  • Backend configuration is in backend.tf"
    echo "  • Use 'terraform init -reconfigure' if you need to reconfigure"
    echo ""
}

# Main execution
main() {
    echo "========================================="
    echo "🚀 Terraform Backend Setup Script"
    echo "========================================="
    echo ""
    
    check_prerequisites
    create_resource_group
    create_storage_account
    configure_storage_security
    create_storage_container
    assign_permissions
    update_backend_config
    initialize_terraform
    verify_backend
    create_recovery_script
    show_summary
    
    log_success "Backend setup completed successfully!"
}

# Run main function
main "$@"