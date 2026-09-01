variable "prefix" {
  description = "Short name prefix used for all resources"
  type        = string
  default     = "murali"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}
variable "app_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}
variable "pe_subnet_cidr" {
  type    = string
  default = "10.10.3.0/24"
}

variable "app_service_sku" {
  type    = string
  default = "B1"
}

variable "sql_sku" {
  type    = string
  default = "Basic"
}

variable "keyvault_allowed_ip_ranges" {
  description = "Public IP addresses/CIDRs allowed to manage Key Vault secrets during terraform apply/destroy (e.g. your workstation's public IP). Leave empty to allow all public traffic to the vault (still protected by Azure RBAC)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type = map(string)
  default = {
    project    = "azure-terraform-demo"
    managed_by = "terraform"
  }
}
