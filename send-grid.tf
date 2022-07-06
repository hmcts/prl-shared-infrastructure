locals {
  sendgrid_subscription = {
    prod    = "8999dec3-0104-4a27-94ee-6588559729d1"
    nonprod = "1c4f0704-a29e-403d-b719-b90c34ef14c9"
  }
}

data "azurerm_key_vault" "send_grid" {
  provider = azurerm.sendgrid

  name                = var.env != "prod" ? "sendgridnonprod" : "sendgridprod"
  resource_group_name = var.env != "prod" ? "SendGrid-nonprod" : "SendGrid-prod"
}

data "azurerm_key_vault_secret" "send_grid_api_key" {
  provider = azurerm.sendgrid

  name         = "hmcts-private-law-api-key"
  key_vault_id = data.azurerm_key_vault.send_grid.id
}

data "azurerm_key_vault_secret" "send_grid_password_key" {
  provider = azurerm.sendgrid

  name         = "hmcts-private-law-password"
  key_vault_id = data.azurerm_key_vault.send_grid.id
}

resource "azurerm_key_vault_secret" "sendgrid_api_key" {
  name         = "send-grid-api-key"
  value        = data.azurerm_key_vault_secret.send_grid_api_key.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "sendgrid_password_key" {
  name         = "send-grid-password"
  value        = data.azurerm_key_vault_secret.send_grid_password_key.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}