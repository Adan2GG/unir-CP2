provider "azurerm" {
  features {}
}

# Crear un grupo de recursos con los valores del fichero de varibales vars(adanUNIRRG - East US)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Crear el Azure Container Registry (aggdevops2 - East US)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.sku
  admin_enabled       = true
}

#Creamos una red virtual (networkagg)
resource "azurerm_virtual_network" "red" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#Creamos una subred (subnetagg)
resource "azurerm_subnet" "subred" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.red.name
  address_prefixes     = ["10.0.2.0/24"]
}

#Creamos una ip publica
resource "azurerm_public_ip" "aggIpPublic" {
  name                = var.ip_public_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

#Creamos un grupo de seguridad para habilitar el puerto 22 por ssh
resource "azurerm_network_security_group" "sec_grup_agg" {
  name                = "AGG-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Creamos una interfaz de red 
resource "azurerm_network_interface" "interred" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "IPPublicAGG"
    subnet_id                     = azurerm_subnet.subred.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aggIpPublic.id
  }
}

