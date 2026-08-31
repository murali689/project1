resource "azurerm_service_plan" "this" {
  name                = "${var.prefix}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "${var.prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
    application_stack {
      node_version = var.node_version
    }
  }

  # No secrets hardcoded here: Key Vault URI is passed so the app
  # can fetch secrets itself at runtime using its Managed Identity.
  app_settings = {
    "KEY_VAULT_URI"                       = var.key_vault_uri
    "WEBSITE_RUN_FROM_PACKAGE"            = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"      = "false"
  }
}

# VNet Integration into the Private App subnet
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = var.app_subnet_id
}
