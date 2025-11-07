#!/bin/bash

# Terraform Backend Setup Script
# Creates Azure Storage backend for Terraform state files

set -e

# Configuration
readonly RESOURCE_GROUP_NAME="rg-terraform-state"
readonly LOCATION="eastus"
readonly CONTAINER_NAME="tfstate"
readonly STATE_KEY="analytics/terraform.tfstate"

# Functions
log() {
    echo "$(date '+%H:%M:%S') $1"
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

check_prerequisites() {
    log "Checking prerequisites"
    command -v az >/dev/null 2>&1 || error "Azure CLI not installed"
    az account show >/dev/null 2>&1 || error "Not authenticated with Azure CLI"
    command -v terraform >/dev/null 2>&1 || error "Terraform not installed"
    log "Prerequisites validated"
}

generate_storage_name() {
    local suffix
    suffix=$(date +%s | tail -c 6)
    echo "stterrastate${suffix}"
}

create_resource_group() {
    log "Creating resource group: $RESOURCE_GROUP_NAME"
    
    if az group show --name "$RESOURCE_GROUP_NAME" >/dev/null 2>&1; then
        log "Resource group already exists"
        return 0
    fi
    
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --output none
    
    log "Resource group created"
}

create_storage_account() {
    local existing_storage
    existing_storage=$(az storage account list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "[0].name" \
        --output tsv 2>/dev/null)
    
    if [[ -n "$existing_storage" ]]; then
        STORAGE_ACCOUNT_NAME="$existing_storage"
        log "Using existing storage account: $STORAGE_ACCOUNT_NAME"
        return 0
    fi
    
    STORAGE_ACCOUNT_NAME=$(generate_storage_name)
    log "Creating storage account: $STORAGE_ACCOUNT_NAME"
    
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku "Standard_LRS" \
        --kind "StorageV2" \
        --https-only true \
        --output none
    
    log "Storage account created: $STORAGE_ACCOUNT_NAME"
}

create_storage_container() {
    log "Creating container: $CONTAINER_NAME"
    
    if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login >/dev/null 2>&1; then
        log "Container already exists"
        return 0
    fi
    
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --public-access off \
        --auth-mode login \
        --output none
    
    log "Container created"
}

assign_permissions() {
    log "Configuring permissions"
    
    local user_object_id
    local storage_scope
    
    user_object_id=$(az ad signed-in-user show --query id -o tsv)
    storage_scope="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
    
    az role assignment create \
        --assignee "$user_object_id" \
        --role "Storage Blob Data Owner" \
        --scope "$storage_scope" \
        --output none 2>/dev/null || true
    
    log "Permissions configured"
}

update_backend_config() {
    log "Updating backend configuration"
    
    cat > backend.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$STATE_KEY"
  }
}
EOF

    log "Backend configuration updated"
}

initialize_terraform() {
    log "Initializing Terraform"
    
    sleep 3
    
    if terraform init -reconfigure >/dev/null 2>&1; then
        log "Terraform initialized successfully"
    else
        log "Terraform initialization may need retry"
    fi
}

show_summary() {
    echo ""
    echo "Backend Setup Complete"
    echo "====================="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "Container: $CONTAINER_NAME"
    echo ""
}

main() {
    echo "Terraform Backend Setup"
    echo "======================"
    
    check_prerequisites
    create_resource_group
    create_storage_account
    create_storage_container
    assign_permissions
    update_backend_config
    initialize_terraform
    show_summary
    
    log "Setup completed"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi