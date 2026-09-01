data "azurerm_client_config" "current" {}

# ---------------------------------------------------------
# Key Vault
# ---------------------------------------------------------
resource "azurerm_key_vault" "this" {
  name                = "${var.prefix}-keyvault-07"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Public network access stays enabled (locked down via network_acls below)
  # because Terraform itself runs from outside the VNet and needs a path to
  # write secrets. The App Service reaches the vault privately over the
  # Private Endpoint created by the "key_vault_private_endpoint" module in
  # root main.tf. If public_network_access_enabled were false here, every
  # `terraform apply`/`destroy` that touches secrets would fail with 403
  # ForbiddenByConnection, since a Private Endpoint only grants access to
  # traffic that originates inside the linked VNet.
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass         = "AzureServices"
    default_action = length(var.allowed_ip_ranges) > 0 ? "Deny" : "Allow"
    ip_rules       = var.allowed_ip_ranges
  }

  # Use Azure RBAC for Key Vault permissions
  enable_rbac_authorization = true

  tags = var.tags
}

# ---------------------------------------------------------
# App Service → Key Vault Secrets User
# ---------------------------------------------------------
resource "azurerm_role_assignment" "app_service_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_service_principal_id
}

# ---------------------------------------------------------
# Deployer / CI → Key Vault Secrets Officer
# ---------------------------------------------------------
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_principal_id
}

# Wait for RBAC role assignments to propagate (can take 30-60 seconds)
# This is critical because terraform plan tries to read secrets immediately
# after creating role assignments, and Azure RBAC changes are eventually consistent
resource "time_sleep" "rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.deployer_secrets_officer,
    azurerm_role_assignment.app_service_secrets_user
  ]

  create_duration = "90s"
}

# ---------------------------------------------------------
# Application Insights Connection String
# ---------------------------------------------------------
resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "AppInsights-ConnectionString"
  value        = var.app_insights_connection_string
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    time_sleep.rbac_propagation
  ]
}

# ---------------------------------------------------------
# SQL Connection String
# ---------------------------------------------------------
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "Sql-ConnectionString"
  value        = var.sql_connection_string
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    time_sleep.rbac_propagation
  ]
}