variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "resource_prefix" {
  description = "(Optional) Prefix to use for all resoruces created (Defaults to resource_group_name)"
  default     = ""
}

variable "virtual_network" {
  description = "The name and resource group of the virtual network"
  type        = object({ name = string, resource_group_name = string })
  default     = { name = "", resource_group_name = "" }
}

variable "create_public_ip_prefix" {
  description = "(Optional) Indicates if a new public ip prefix should be created (default true)"
  default     = true
}

variable "public_ip_prefix_resource_group_name" {
  description = "(Optional) The resource group that contains the public ip prefix (defaults to hub resource group)"
  default     = null
}

variable "public_ip_prefix_name" {
  description = "(Optional) The name of the public prefix to use"
  default     = null
}

variable "public_ip_allocation_method" {
  description = "Defines the allocation method for this IP address. Possible values are Static or Dynamic"
  default     = "Static"
}

variable "public_ip_sku" {
  description = "The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic"
  default     = "Standard"
}

variable "domain_name_label" {
  description = "Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system"
  default     = null
}

variable "azure_bastion_service_name" {
  description = "Specifies the name of the Bastion Host"
  default     = ""
}

variable "azure_bastion_subnet_address_prefix" {
  description = "The address prefix to use for the Azure Bastion subnet"
  default     = []
}

variable "enable_copy_paste" {
  description = "Is Copy/Paste feature enabled for the Bastion Host?"
  default     = true
}

variable "enable_file_copy" {
  description = "Is File Copy feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
  default     = false
}

variable "bastion_host_sku" {
  description = "The SKU of the Bastion Host. Accepted values are `Basic` and `Standard`"
  default     = "Basic"
}

variable "enable_ip_connect" {
  description = "Is IP Connect feature enabled for the Bastion Host?"
  default     = false
}

variable "scale_units" {
  description = "The number of scale units with which to provision the Bastion Host. Possible values are between `2` and `50`. `scale_units` only can be changed when `sku` is `Standard`. `scale_units` is always `2` when `sku` is `Basic`."
  default     = 2
}

variable "enable_shareable_link" {
  description = "Is Shareable Link feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
  default     = false
}

variable "enable_tunneling" {
  description = "Is Tunneling feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
