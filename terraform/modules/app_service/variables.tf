variable "prefix"              { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "app_subnet_id"       { type = string }
variable "key_vault_uri"       { type = string }
variable "node_version" {
  type    = string
  default = "18-lts"
}
variable "sku_name" {
  type    = string
  default = "B1"
}
variable "tags" {
  type    = map(string)
  default = {}
}
