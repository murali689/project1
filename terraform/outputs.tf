output "resource_group_name" { value = module.resource_group.name }
output "app_service_name" { value = module.app_service.name }
output "app_service_hostname" { value = module.app_service.default_hostname }
output "key_vault_name" { value = module.key_vault.name }
output "key_vault_uri" { value = module.key_vault.vault_uri }
output "sql_server_fqdn" { value = module.sql_database.server_fqdn }
output "sql_database_name" { value = module.sql_database.database_name }
output "app_insights_id" { value = module.app_insights.id }
