# ---------------------------------------------------------------------------
# Root module: wires together all child modules
# ---------------------------------------------------------------------------

module "resource_group" {
  source   = "./modules/resource_group"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "./modules/network"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_cidr           = var.vnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  app_subnet_cidr     = var.app_subnet_cidr
  pe_subnet_cidr      = var.pe_subnet_cidr
  tags                = var.tags
}

module "app_insights" {
  source              = "./modules/app_insights"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "sql_database" {
  source              = "./modules/sql_database"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  sku_name            = var.sql_sku
  tags                = var.tags
}

# NOTE: the Key Vault URI is deterministic (https://<name>.vault.azure.net/),
# so we build it from the naming convention instead of referencing
# module.key_vault directly. That would create a dependency cycle, because
# Key Vault's role assignment below needs this module's principal_id.
locals {
  # Must match the name used in modules/key_vault/main.tf (azurerm_key_vault.this.name)
  key_vault_name = "${var.prefix}-kv-2026"
  key_vault_uri  = "https://${local.key_vault_name}.vault.azure.net/"
}

# App Service is created before Key Vault secrets so its Managed Identity
# principal_id can be granted access to Key Vault.
module "app_service" {
  source              = "./modules/app_service"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  app_subnet_id       = module.network.app_subnet_id
  key_vault_uri       = local.key_vault_uri
  sku_name            = var.app_service_sku
  tags                = var.tags
}

module "key_vault" {
  source = "./modules/key_vault"

  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name

  app_service_principal_id = module.app_service.principal_id
  deployer_principal_id    = data.azurerm_client_config.current.object_id

  app_insights_connection_string = module.app_insights.connection_string
  sql_connection_string          = module.sql_database.connection_string

  allowed_ip_ranges = var.keyvault_allowed_ip_ranges

  tags = var.tags
}

# Private Endpoint locking Key Vault to the private network
module "key_vault_private_endpoint" {
  source              = "./modules/private_endpoint"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.pe_subnet_id
  vnet_id             = module.network.vnet_id
  key_vault_id        = module.key_vault.id
  tags                = var.tags
}
