provider "azurerm" {
  features {}
}

# Crear un grupo de recursos con los valores del fichero de varibales vars
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Crear el Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.sku
  admin_enabled       = true
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "admin_password" {
  value = azurerm_container_registry.acr.admin_password
  sensitive = true
}