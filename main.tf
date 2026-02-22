terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

variable "prefix" {
  type    = string
  default = "devopsdemo"
}

variable "location" {
  type    = string
  default = "northeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = lower("${var.prefix}acr")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "web" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      docker_image_name   = "mcr.microsoft.com/oss/nginx/nginx:1.21"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "web_app_name" {
  value = azurerm_linux_web_app.web.name
}

output "rg" {
  value = azurerm_resource_group.rg.name
}
