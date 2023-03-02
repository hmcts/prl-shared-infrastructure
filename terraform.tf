provider "azurerm" {
  features {}
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
      version = "2.35.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.45.0"
    }
  }
}