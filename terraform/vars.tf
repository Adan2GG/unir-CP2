variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "adanUNIRRG"
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
  default     = "aggdevops2"
}

variable "sku" {
  description = "The SKU of the Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "network_name" {
  description = "The name of the Azure network"
  type        = string
  default     = "networkagg"
}

variable "subnet_name" {
  description = "The name of the Azure subnet"
  type        = string
  default     = "subnetagg"
}

variable "nic_name" {
  description = "The name of the Azure intefaz net"
  type        = string
  default     = "nicagg"
}

variable "vm_name" {
  description = "The name of the Azure Virtual Machine"
  type        = string
  default     = "vmUbuntuagg"
}

variable "adminuser" {
  description = "The value of adminuser of VM Ubuntu"
  type        = string
  default     = "ubuntu"
}

variable "computer_name" {
  description = "The name of VM"
  type        = string
  default     = "ubuntuagg"
}

variable "admin_pass" {
  description = "The value of pss admin of VM"
  type        = string
  default     = "ubuntuagg"
}

variable "clusteraks_name" {
  description = "The value of pss admin of VM"
  type        = string
  default     = "akagg"
}
