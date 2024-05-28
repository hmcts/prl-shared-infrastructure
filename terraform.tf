provider "azurerm" {
  features {}
  subscription_id = var.aks_subscription_id
}

provider "azurerm" {
  alias           = "sendgrid"
  subscription_id = var.env != "prod" ? local.sendgrid_subscription.nonprod : local.sendgrid_subscription.prod
  features {}
}

terraform {
  backend "azurerm" {}

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.39.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.78.0"
    }
  }
}