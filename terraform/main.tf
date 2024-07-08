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

#Creamos una red virtual
resource "azurerm_virtual_network" "red" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#Creamos una subred
resource "azurerm_subnet" "subred" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.red.name
  address_prefixes     = ["10.0.2.0/24"]
}

#Creamos una interfaz de red
resource "azurerm_network_interface" "interred" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subred.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Creamos la máquina virtual
resource "azurerm_linux_virtual_machine" "mvlinux" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = var.adminuser
  network_interface_ids = [
    azurerm_network_interface.interred.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = var.computer_name
  admin_password = var.admin_pass

  disable_password_authentication = false

  tags = {
    environment = "Terraform VMLinux"
  }
}

#Creamos el cluster de kubernetes
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.clusteraks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-cluster"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.subred.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Terraform AKS"
  }
}
