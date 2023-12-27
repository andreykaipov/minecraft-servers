terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = ">= 1.0, < 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.0, < 4.0"
    }
  }
}


locals {
  secrets = {
    for e in one(data.onepassword_item.secrets.section).field :
    e.label => e.value
  }

  az_service_principal = jsondecode(local.secrets["az_service_principal_json"])
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  client_id                  = local.az_service_principal.appId
  client_secret              = local.az_service_principal.password
  tenant_id                  = local.az_service_principal.tenant
  subscription_id            = local.az_service_principal.subscriptionId
}

provider "cloudflare" {
  api_token = local.secrets["cloudflare_api_token"]
}
