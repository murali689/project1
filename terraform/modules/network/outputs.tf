output "vnet_id" { value = azurerm_virtual_network.this.id }
output "public_subnet_id" { value = azurerm_subnet.public.id }
output "app_subnet_id" { value = azurerm_subnet.app.id }
output "pe_subnet_id" { value = azurerm_subnet.pe.id }
