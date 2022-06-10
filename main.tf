#---------------------------------
# Local declarations
#---------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  resource_prefix     = var.resource_prefix == "" ? local.resource_group_name : var.resource_prefix
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)

  timeout_create  = "15m"
  timeout_update  = "15m"
  timeout_delete  = "15m"
  timeout_read    = "15m"
}

#---------------------------------------------------------
# Random Data
#----------------------------------------------------------
resource "random_string" "str" {
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.azure_bastion_service_name
  }
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "true"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network.name
  resource_group_name = var.virtual_network.resource_group_name
}

#-----------------------------------------------------------------------
# Subnets Creation for Azure Bastion Service - at least /27 or larger.
#-----------------------------------------------------------------------
data "azurerm_subnet" "abs_snet" {
  count                = var.azure_bastion_subnet_address_prefix != null ? 0 : 1
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "abs_snet" {
  count                = var.azure_bastion_subnet_address_prefix != null ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = var.azure_bastion_subnet_address_prefix
}

#---------------------------------------------
# Public IP for Azure Bastion Service
#---------------------------------------------
data "azurerm_public_ip_prefix" "pip_prefix" {
  count               = var.create_public_ip_prefix ? 0 : 1
  name                = var.public_ip_prefix_name
  resource_group_name = var.public_ip_prefix_resource_group_name != null ? var.public_ip_prefix_resource_group_name : local.resource_group_name
}

resource "azurerm_public_ip_prefix" "pip_prefix" {
  count               = var.create_public_ip_prefix ? 1 : 0
  name                = lower("${local.resource_prefix}-pip-prefix")
  location            = local.location
  resource_group_name = var.public_ip_prefix_resource_group_name != null ? var.public_ip_prefix_resource_group_name : local.resource_group_name
  prefix_length       = 30

  tags                = merge({ "ResourceName" = lower("${local.resource_prefix}-pip-prefix") }, var.tags, )
}

resource "azurerm_public_ip" "pip" {
  name                = lower("${local.resource_prefix}-${var.azure_bastion_service_name}-pip")
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  public_ip_prefix_id = element(coalescelist(data.azurerm_public_ip_prefix.pip_prefix.*.id, azurerm_public_ip_prefix.pip_prefix.*.id, [""]), 0)
  domain_name_label   = var.domain_name_label != null ? var.domain_name_label : format("gw%s%s", lower(replace(var.azure_bastion_service_name, "/[[:^alnum:]]/", "")), random_string.str.result)

  tags                = merge({ "ResourceName" = "${local.resource_prefix}-${lower(var.azure_bastion_service_name)}-pip" }, var.tags, )

  lifecycle {
    ignore_changes = [
      tags,
      ip_tags,
    ]
  }
}

#---------------------------------------------
# Azure Bastion Service host
#---------------------------------------------
resource "azurerm_bastion_host" "main" {
  name                   = lower("${local.resource_prefix}-${var.azure_bastion_service_name}")
  location               = local.location
  resource_group_name    = local.resource_group_name
  copy_paste_enabled     = var.enable_copy_paste
  file_copy_enabled      = var.bastion_host_sku == "Standard" ? var.enable_file_copy : null
  sku                    = var.bastion_host_sku
  ip_connect_enabled     = var.enable_ip_connect
  scale_units            = var.bastion_host_sku == "Standard" ? var.scale_units : 2
  shareable_link_enabled = var.bastion_host_sku == "Standard" ? var.enable_shareable_link : null
  tunneling_enabled      = var.bastion_host_sku == "Standard" ? var.enable_tunneling : null
  
  tags                   = merge({ "ResourceName" = "${local.resource_prefix}}-${lower(var.azure_bastion_service_name)}" }, var.tags, )

  ip_configuration {
    name                 = "${local.resource_prefix}-${lower(var.azure_bastion_service_name)}-network"
    subnet_id            = element(coalescelist(data.azurerm_subnet.abs_snet.*.id, azurerm_subnet.abs_snet.*.id, [""]), 0)
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

