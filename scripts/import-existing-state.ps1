$ErrorActionPreference = "Stop"

$subscriptionId = az account show --query id -o tsv
if (-not $subscriptionId) {
    throw "Azure CLI is not logged in. Run 'az login' first."
}

$rg = "murali-rg"
$prefix = "murali"
$vnet = "$prefix-vnet"

$resourceGroupId = "/subscriptions/$subscriptionId/resourceGroups/$rg"
$networkId = "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnet"

$imports = @(
    "module.resource_group.azurerm_resource_group.this|$resourceGroupId",
    "module.network.azurerm_virtual_network.this|$networkId",
    "module.network.azurerm_subnet.public|$networkId/subnets/snet-public",
    "module.network.azurerm_subnet.app|$networkId/subnets/snet-app",
    "module.network.azurerm_subnet.pe|$networkId/subnets/snet-private-endpoint",
    "module.key_vault.azurerm_key_vault.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.KeyVault/vaults/$prefix-keyvault-07",
    "module.app_insights.azurerm_log_analytics_workspace.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.OperationalInsights/workspaces/$prefix-law",
    "module.app_insights.azurerm_application_insights.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Insights/components/$prefix-appinsights",
    "module.app_service.azurerm_service_plan.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Web/serverFarms/$prefix-plan",
    "module.app_service.azurerm_linux_web_app.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Web/sites/$prefix-app",
    "module.sql_database.azurerm_mssql_server.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Sql/servers/$prefix-sqlsrv",
    "module.sql_database.azurerm_mssql_database.this|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Sql/servers/$prefix-sqlsrv/databases/$prefix-sqldb",
    "module.key_vault_private_endpoint.azurerm_private_dns_zone.kv|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net",
    "module.key_vault_private_endpoint.azurerm_private_endpoint.kv|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/privateEndpoints/$prefix-kv-pe",
    "module.key_vault_private_endpoint.azurerm_private_dns_zone_virtual_network_link.kv|/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net/virtualNetworkLinks/$prefix-kv-dns-link"
)

Set-Location "$PSScriptRoot/../terraform"
terraform init -reconfigure

foreach ($entry in $imports) {
    $parts = $entry.Split('|', 2)
    $resource = $parts[0]
    $id = $parts[1]

    Write-Host "Importing $resource -> $id"
    terraform import -lock=false $resource $id
}

Write-Host "Import complete. Run 'terraform plan' to confirm the state matches Azure."
