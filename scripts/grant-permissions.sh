#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# grant-permissions.sh
#
# One-time setup script that grants your GitHub Actions service principal
# (App Registration) all the RBAC roles it needs to run Terraform and
# deploy this project. Run this ONCE locally after `az login`, using an
# account that has Owner (or User Access Administrator) rights on the
# subscription, resource groups, storage account, and key vault involved.
#
# Usage:
#   1. Fill in the variables below with your actual values.
#   2. chmod +x scripts/grant-permissions.sh
#   3. ./scripts/grant-permissions.sh
# ---------------------------------------------------------------------------

set -euo pipefail

# ------------------------- EDIT THESE VALUES --------------------------------

# The Application (client) ID of your GitHub Actions app registration
APP_CLIENT_ID="9c36b1ba-fe8a-4c9a-9840-8f4e050c87d3"

# Your Azure Subscription ID (same value as GitHub secret AZURE_SUBSCRIPTION_ID)
SUBSCRIPTION_ID="996d1b6a-eec5-418d-b351-9af66fcd25dc"

# Terraform remote state backend (same values as GitHub secrets
# TFSTATE_RG / TFSTATE_SA / TFSTATE_CONTAINER)
TFSTATE_RESOURCE_GROUP="vaishnavi-backend-rg"
TFSTATE_STORAGE_ACCOUNT="vaishnavisa"

# Resource group + Key Vault name used by the actual application infra
# (the ones your terraform/*.tf files create/manage)
APP_RESOURCE_GROUP="vaishnavi-rg"
KEY_VAULT_NAME="vaishnavi-keyvault-07"

# ------------------------- DO NOT EDIT BELOW --------------------------------

echo "Looking up service principal object ID for client ID: $APP_CLIENT_ID"
APP_OBJECT_ID=$(az ad sp show --id "$APP_CLIENT_ID" --query "id" -o tsv)
echo "Found object ID: $APP_OBJECT_ID"

echo ""
echo "1) Granting Contributor role on the subscription..."
az role assignment create \
  --assignee-object-id "$APP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo ""
echo "2) Granting Storage Blob Data Contributor on the Terraform state storage account..."
STORAGE_ACCOUNT_ID=$(az storage account show \
  --name "$TFSTATE_STORAGE_ACCOUNT" \
  --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --query "id" -o tsv)

az role assignment create \
  --assignee-object-id "$APP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ACCOUNT_ID"

echo ""
echo "3) Granting Key Vault Secrets Officer on the application Key Vault..."
KEY_VAULT_ID=$(az keyvault show \
  --name "$KEY_VAULT_NAME" \
  --resource-group "$APP_RESOURCE_GROUP" \
  --query "id" -o tsv)

az role assignment create \
  --assignee-object-id "$APP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets Officer" \
  --scope "$KEY_VAULT_ID"

echo ""
echo "All role assignments requested. Note: Azure RBAC can take a few minutes"
echo "to propagate. Wait 2-5 minutes before re-running the GitHub Actions workflow."