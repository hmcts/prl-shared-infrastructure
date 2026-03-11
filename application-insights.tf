module "application_insights" {
  source = "git@github.com:hmcts/terraform-module-application-insights?ref=4.x"

  env     = var.env
  product = var.product
  name    = "${var.product}-appinsights"

  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  common_tags         = var.common_tags
}

moved {
  from = azurerm_application_insights.appinsights
  to   = module.application_insights.azurerm_application_insights.this
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY_PREVIEW" {
  name         = "AppInsightsInstrumentationKey-Preview"
  value        = module.application_insights_preview[0].instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
  count        = var.env == "aat" ? 1 : 0
}

module "application_insights_preview" {
  count    = var.env == "aat" ? 1 : 0
  source   = "git@github.com:hmcts/terraform-module-application-insights?ref=4.x"
  location = var.location
  env      = "preview"
  product  = var.product
  name     = "${var.product}-appinsights"

  resource_group_name = azurerm_resource_group.rg.name

  common_tags = var.common_tags
}

moved {
  from = azurerm_application_insights.appinsights_preview[0]
  to   = module.application_insights_preview[0].azurerm_application_insights.this
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY" {
  name         = "AppInsightsInstrumentationKey"
  value        = module.application_insights.instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = module.application_insights.connection_string
  key_vault_id = data.azurerm_key_vault.key_vault.id
}
