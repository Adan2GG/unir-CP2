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
    name                          = "IPPublicAGG"
    subnet_id                     = azurerm_subnet.subred.id
    private_ip_address_allocation = "Dynamic"
  }
}
#Creamos una ip publica
resource "azurerm_public_ip" "aggIpPublic" {
  name                = "aggIpPublic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
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
  #Config ssh conexión
  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("~/.ssh/id_rsa.pub")
  }
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

#Asociamos el ACR con el AKS para permitir que el AKS tenga acceso al ACR.
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope         = azurerm_container_registry.acr.id
}

#Obtenemos las credenciales de ACR
data "azurerm_container_registry" "acr" {
  name                = azurerm_container_registry.acr.name
  resource_group_name = azurerm_container_registry.acr.resource_group_name
}

#Creamos un secreto en Kubernetes con local-exec
resource "null_resource" "create_k8s_secret" {
  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --admin
      kubectl create secret docker-registry acr-auth \
        --docker-server=${data.azurerm_container_registry.acr.login_server} \
        --docker-username=${data.azurerm_container_registry.acr.admin_username} \
        --docker-password=${data.azurerm_container_registry.acr.admin_password} \
        --docker-email=example@example.com
    EOT
  }
}

