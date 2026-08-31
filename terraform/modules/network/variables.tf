variable "prefix"              { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "vnet_cidr"           { type = string }
variable "public_subnet_cidr"  { type = string }
variable "app_subnet_cidr"     { type = string }
variable "pe_subnet_cidr"      { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
