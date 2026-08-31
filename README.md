# Azure Terraform Demo: App Service + SQL + Key Vault + App Insights + VNet

## Structure
```
Project/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Build -> Infra -> App Deploy
├── app/                         # Node.js/Express sample app
│   ├── package.json
│   ├── package-lock.json
│   └── server.js
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── backend.tf
│   └── modules/
│       ├── resource_group/
│       ├── network/
│       ├── app_service/
│       ├── sql_database/
│       ├── key_vault/
│       ├── private_endpoint/
│       └── app_insights/
├── .gitignore
└── README.md
```

## Network
One VNet (`10.10.0.0/16`) with:
- `snet-public` – public-facing subnet
- `snet-app` – delegated to `Microsoft.Web/serverFarms`, used for App Service VNet Integration
- `snet-private-endpoint` – hosts the Key Vault Private Endpoint

## Security
- Key Vault: `public_network_access_enabled = false`, reachable only via its Private Endpoint + Private DNS zone.
- App Service uses a **System-Assigned Managed Identity**, granted the **Key Vault Secrets User** RBAC role — no credentials in code.
- App Insights connection string and the SQL connection string are stored as Key Vault secrets; the app fetches them at startup via `DefaultAzureCredential` (Managed Identity).
- The Terraform-deploying identity (CI's OIDC service principal) is auto-granted **Key Vault Secrets Officer** so `terraform apply` can write secrets.
- SQL admin password is generated with `random_password` — never hardcoded, never displayed (marked `sensitive`).

## Deploy locally
```bash
cd terraform
terraform init -backend-config="resource_group_name=<rg>" \
                -backend-config="storage_account_name=<sa>" \
                -backend-config="container_name=<container>" \
                -backend-config="key=demoapp.terraform.tfstate"
terraform plan
terraform apply
```

## CI/CD (GitHub Actions)
Configure repo secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (federated OIDC app registration — no client secret needed), plus `TFSTATE_RG`, `TFSTATE_SA`, `TFSTATE_CONTAINER` for remote state.

Pipeline stages (`.github/workflows/deploy.yml`), run in order:
1. **build** – checkout, `npm ci`, `npm test`, zip artifact
2. **infra** – `terraform init/validate/plan/apply` via OIDC login
3. **deploy-app** – `azure/webapps-deploy` publishes the zip to App Service

## Notes
- SQL is reachable via `AllowAzureServices` firewall rule for this demo; for stricter isolation, add a Private Endpoint for SQL the same way it's done for Key Vault.
- Change `prefix`/`location` in `terraform.tfvars.example` (copy to `terraform.tfvars`) per environment.
