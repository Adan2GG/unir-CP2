#Creamos la máquina virtual vmUbuntuagg
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
  connection {
      type        = "ssh"
      user        = var.adminuser
      password    = var.admin_pass
      host        = azurerm_public_ip.aggIpPublic.ip_address
      timeout     = "5m"
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
  #Para evitar el error de conflicto de rangos entre CIDR y la subred
  network_profile {
    network_plugin = "azure"
    service_cidr = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
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
