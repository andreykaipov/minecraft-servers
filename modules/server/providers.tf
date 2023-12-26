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
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  client_id                  = local.az_service_principal.appId
  client_secret              = local.az_service_principal.password
  tenant_id                  = local.az_service_principal.tenant
  subscription_id            = local.az_service_principal.subscriptionId
}
