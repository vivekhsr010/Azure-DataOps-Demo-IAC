#!/bin/bash

# =============================================================================
# Backend Status Check Script
# =============================================================================
# This script checks the status and health of your Terraform backend
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "========================================="
echo "🔍 Terraform Backend Health Check"
echo "========================================="
echo ""

# Check if authenticated with Azure
log_info "Checking Azure CLI authentication..."
if az account show &> /dev/null; then
    ACCOUNT_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    log_success "Authenticated with Azure: $ACCOUNT_NAME"
    echo "    Subscription: $SUBSCRIPTION_ID"
else
    log_error "Not authenticated with Azure CLI. Run 'az login'"
    exit 1
fi

echo ""

# Check backend configuration
log_info "Checking backend configuration..."
if [ -f "backend.tf" ]; then
    log_success "backend.tf exists"
    
    # Extract backend values (exclude commented lines)
    RG_NAME=$(grep -v '^#' backend.tf | grep -o 'resource_group_name.*=.*"[^"]*"' | cut -d'"' -f2 | head -1)
    STORAGE_NAME=$(grep -v '^#' backend.tf | grep -o 'storage_account_name.*=.*"[^"]*"' | cut -d'"' -f2 | head -1)
    CONTAINER_NAME=$(grep -v '^#' backend.tf | grep -o 'container_name.*=.*"[^"]*"' | cut -d'"' -f2 | head -1)
    STATE_KEY=$(grep -v '^#' backend.tf | grep -o 'key.*=.*"[^"]*"' | cut -d'"' -f2 | head -1)
    
    echo "    Resource Group: $RG_NAME"
    echo "    Storage Account: $STORAGE_NAME"
    echo "    Container: $CONTAINER_NAME"
    echo "    State Key: $STATE_KEY"
else
    log_error "backend.tf not found"
    exit 1
fi

echo ""

# Check if backend resources exist
log_info "Checking backend resources..."

# Check resource group
if az group show --name "$RG_NAME" &> /dev/null; then
    log_success "Resource group '$RG_NAME' exists"
else
    log_error "Resource group '$RG_NAME' not found"
    exit 1
fi

# Check storage account
if az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" &> /dev/null; then
    log_success "Storage account '$STORAGE_NAME' exists"
    
    # Check storage account security features
    VERSIONING=$(az storage account blob-service-properties show --account-name "$STORAGE_NAME" --query isVersioningEnabled -o tsv)
    DELETE_RETENTION=$(az storage account blob-service-properties show --account-name "$STORAGE_NAME" --query deleteRetentionPolicy.enabled -o tsv)
    
    if [ "$VERSIONING" = "true" ]; then
        log_success "Blob versioning enabled"
    else
        log_warning "Blob versioning not enabled"
    fi
    
    if [ "$DELETE_RETENTION" = "true" ]; then
        RETENTION_DAYS=$(az storage account blob-service-properties show --account-name "$STORAGE_NAME" --query deleteRetentionPolicy.days -o tsv)
        log_success "Soft delete enabled ($RETENTION_DAYS days)"
    else
        log_warning "Soft delete not enabled"
    fi
else
    log_error "Storage account '$STORAGE_NAME' not found"
    exit 1
fi

# Check container
if az storage container show --name "$CONTAINER_NAME" --account-name "$STORAGE_NAME" --auth-mode login &> /dev/null; then
    log_success "Container '$CONTAINER_NAME' exists"
else
    log_error "Container '$CONTAINER_NAME' not found"
fi

echo ""

# Check Terraform state
log_info "Checking Terraform state..."

if [ -f "terraform.tfstate" ]; then
    STATE_SIZE=$(wc -c < "terraform.tfstate")
    if [ "$STATE_SIZE" -lt 100 ]; then
        log_success "Local state file is minimal (using remote backend)"
    else
        log_warning "Local state file is large (${STATE_SIZE} bytes)"
        log_warning "You may still be using local backend"
    fi
else
    log_info "No local terraform.tfstate file (good for remote backend)"
fi

# Test Terraform state access
if terraform state list &> /dev/null; then
    STATE_COUNT=$(terraform state list | wc -l)
    log_success "Terraform state accessible ($STATE_COUNT resources)"
    
    if [ "$STATE_COUNT" -gt 0 ]; then
        echo "    Resources in state:"
        terraform state list | sed 's/^/      /'
    fi
else
    log_warning "Cannot access Terraform state"
    echo "    This might be normal if no resources are deployed yet"
fi

echo ""

# Check permissions
log_info "Checking access permissions..."
USER_ID=$(az ad signed-in-user show --query id -o tsv)
STORAGE_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME"

if az role assignment list --assignee "$USER_ID" --scope "$STORAGE_SCOPE" --query "[?roleDefinitionName=='Storage Blob Data Owner']" -o tsv | grep -q .; then
    log_success "Storage Blob Data Owner role assigned"
else
    log_warning "Storage Blob Data Owner role not found"
    log_info "You may need to run: az role assignment create --assignee $USER_ID --role 'Storage Blob Data Owner' --scope '$STORAGE_SCOPE'"
fi

echo ""

# Backend health summary
echo "========================================="
echo -e "${GREEN}🏥 Backend Health Summary${NC}"
echo "========================================="

if az storage blob show \
    --container-name "$CONTAINER_NAME" \
    --name "$STATE_KEY" \
    --account-name "$STORAGE_NAME" \
    --auth-mode login &> /dev/null; then
    
    # Get state file info
    LAST_MODIFIED=$(az storage blob show \
        --container-name "$CONTAINER_NAME" \
        --name "$STATE_KEY" \
        --account-name "$STORAGE_NAME" \
        --auth-mode login \
        --query properties.lastModified -o tsv)
    
    BLOB_SIZE=$(az storage blob show \
        --container-name "$CONTAINER_NAME" \
        --name "$STATE_KEY" \
        --account-name "$STORAGE_NAME" \
        --auth-mode login \
        --query properties.contentLength -o tsv)
    
    log_success "Remote state file exists"
    echo "    Size: $BLOB_SIZE bytes"
    echo "    Last Modified: $LAST_MODIFIED"
    
    # Check for versions
    # Check if versioning is working (simplified check)
    VERSION_COUNT=$(az storage blob list \
        --container-name "$CONTAINER_NAME" \
        --prefix "$STATE_KEY" \
        --account-name "$STORAGE_NAME" \
        --auth-mode login \
        --query "length([?name=='$STATE_KEY'])" -o tsv)
    
    log_success "State file versioning is enabled ($VERSION_COUNT current versions)"
else
    log_warning "Remote state file not found (normal if no 'terraform apply' has been run)"
fi

echo ""
echo -e "${BLUE}💡 Useful Commands:${NC}"
echo "  terraform init -reconfigure    # Reinitialize backend"
echo "  terraform state list           # List resources in state"
echo "  terraform state show <resource> # Show resource details"
echo "  scripts/backup-state.sh        # Backup state file"
echo ""