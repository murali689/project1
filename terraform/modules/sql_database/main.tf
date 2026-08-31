resource "random_password" "sql_admin" {
  length      = 20
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "azurerm_mssql_server" "this" {
  name                          = "${var.prefix}-sqlsrv"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "12.0"
  administrator_login           = var.admin_username
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true # tightened via firewall rules below; use PE for production
  tags                          = var.tags
}

resource "azurerm_mssql_database" "this" {
  name           = "${var.prefix}-sqldb"
  server_id      = azurerm_mssql_server.this.id
  sku_name       = var.sku_name
  max_size_gb    = 2
  zone_redundant = false
  tags           = var.tags
}

# Allow Azure services (App Service outbound) to reach the server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
