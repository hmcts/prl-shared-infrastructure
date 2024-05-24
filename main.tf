resource "azurerm_resource_group" "rg" {
  name     = "${var.product}-${var.env}"
  location = var.location

  tags = var.common_tags
}

module "key-vault" {
  source              = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  product             = var.product
  env                 = var.env
  tenant_id           = var.tenant_id
  object_id           = var.jenkins_AAD_objectId
  resource_group_name = azurerm_resource_group.rg.name

  # dcd_platformengineering group object ID
  product_group_name      = "DTS Family Private Law"
  common_tags             = var.common_tags
  create_managed_identity = true
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY" {
  name         = "AppInsightsInstrumentationKey"
  value        = module.application_insights.instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

module "application_insights" {
  source = "git@github.com:hmcts/terraform-module-application-insights?ref=main"

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
  source   = "git@github.com:hmcts/terraform-module-application-insights?ref=main"
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

data "azurerm_key_vault" "key_vault" {
  name                = "${var.product}-${var.env}" # update these values if required
  resource_group_name = "${var.product}-${var.env}" # update these values if required
}

data "azurerm_key_vault" "s2s_vault" {
  name                = "s2s-${var.env}"
  resource_group_name = "rpe-service-auth-provider-${var.env}"
}

data "azurerm_key_vault" "pcq_vault" {
  name                = "pcq-${var.env}"
  resource_group_name = "pcq-${var.env}"
}

data "azurerm_key_vault_secret" "cos_key_from_vault" {
  name         = "microservicekey-prl-cos-api" # update key name e.g. microservicekey-your-name
  key_vault_id = data.azurerm_key_vault.s2s_vault.id
}

data "azurerm_key_vault_secret" "citizen_key_from_vault" {
  name         = "microservicekey-prl-citizen-frontend" # update key name e.g. microservicekey-your-name
  key_vault_id = data.azurerm_key_vault.s2s_vault.id
}

data "azurerm_key_vault_secret" "prl_pcq_key_from_vault" {
  name         = "prl-token-key"
  key_vault_id = data.azurerm_key_vault.pcq_vault.id
}

data "azurerm_key_vault_secret" "prl_pcq_key_from_vault" {
  name         = "prl-pcq-token-key"
  key_vault_id = data.azurerm_key_vault.pcq_vault.id
}

resource "azurerm_key_vault_secret" "cos_api_s2s_secret" {
  name         = "microservicekey-prl-cos-api"
  value        = data.azurerm_key_vault_secret.cos_key_from_vault.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "dgs_api_s2s_secret" {
  name         = "microservicekey-prl-dgs-api"
  value        = data.azurerm_key_vault_secret.cos_key_from_vault.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "citizen_api_s2s_secret" {
  name         = "microservicekey-prl-citizen-frontend"
  value        = data.azurerm_key_vault_secret.citizen_key_from_vault.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "prl_pcq_token_key" {
  name         = "prl-pcq-token-key"
  value        = data.azurerm_key_vault_secret.prl_pcq_key_from_vault.value
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

module "prl-citizen-frontend-session-storage" {
  source                        = "git@github.com:hmcts/cnp-module-redis?ref=master"
  product                       = "${var.product}-${var.citizen_component}-redis"
  location                      = var.location
  env                           = var.env
  common_tags                   = var.common_tags
  private_endpoint_enabled      = true
  redis_version                 = "6"
  business_area                 = "cft"
  public_network_access_enabled = false
  sku_name                      = var.sku_name
  family                        = var.family
  capacity                      = var.capacity

}

resource "azurerm_key_vault_secret" "redis_access_key" {
  name         = "redis-access-key"
  value        = module.prl-citizen-frontend-session-storage.access_key
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = module.application_insights.connection_string
  key_vault_id = data.azurerm_key_vault.key_vault.id
}
