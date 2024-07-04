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