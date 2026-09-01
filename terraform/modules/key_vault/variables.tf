variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "app_service_principal_id" {
  type = string
}

variable "deployer_principal_id" {
  type        = string
  description = "The Object ID of the deployer (Terraform runner) who needs to manage Key Vault secrets. Required for RBAC role assignment."
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "sql_connection_string" {
  type      = string
  sensitive = true
}

variable "public_network_access_enabled" {
  description = "Whether the Key Vault is reachable over the public internet (locked down by network_acls). Needed so Terraform, which runs outside the VNet, can manage secrets. The App Service still uses the Private Endpoint for its own runtime access."
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses/CIDRs (e.g. your workstation or CI runner's egress IP) allowed to manage Key Vault secrets while public_network_access_enabled = true. Leave empty to allow all public traffic (still protected by RBAC); set explicit IPs to lock it down to just those addresses."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}