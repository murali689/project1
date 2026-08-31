# Remote state backend (Azure Storage). Fill in via -backend-config
# at `terraform init` time (also done by the CI pipeline), so no
# secrets/account names are hardcoded here.


terraform {
  backend "azurerm" {
    resource_group_name  = "murali-backend-rg"
    storage_account_name = "muralisatfstate2026"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"

    use_azuread_auth = true
  }
}