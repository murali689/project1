output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "database_name" { value = azurerm_mssql_database.this.name }
output "admin_username" { value = azurerm_mssql_server.this.administrator_login }
output "connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.this.name};User ID=${azurerm_mssql_server.this.administrator_login};Password=${random_password.sql_admin.result};Encrypt=true;Connection Timeout=30;"
  sensitive = true
}
