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
  source                        = "git@github.com:hmcts/cnp-module-redis?ref=4.x"
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

module "prl-citizen-frontend-secondary-session-storage" {
  source                        = "git@github.com:hmcts/cnp-module-redis?ref=4.x"
  product                       = "${var.product}-${var.citizen_component}-secondary-redis"
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

#resource "azurerm_key_vault_secret" "redis_access_key" {
#  name         = "redis-access-key"
#  value        = module.prl-citizen-frontend-secondary-session-storage.access_key
#  key_vault_id = data.azurerm_key_vault.key_vault.id
#}

# Slack alerts function app managed identity principal ID
# Can be provided via variable or uses hardcoded default for prod
# Hardcoded because pipeline service principal lacks access to subscription
# If function app is recreated, update this ID from:
# az functionapp identity show --name prl-slack-alerts --resource-group prl-slack-alerts --query principalId -o tsv
locals {
  # Use variable if provided, otherwise use hardcoded prod value
  slack_alerts_principal_id = var.slack_alerts_principal_id != "" ? var.slack_alerts_principal_id : (
    var.env == "prod" ? "98ec027e-40cb-49db-92de-6e7454ac5cc9" : null
  )
}
