locals {
  spoke-location       = var.location
  spoke-resource-group = "private-endpoint-openhack-spoke-rg"
  prefix-spoke         = "spoke"
}

resource "azurerm_resource_group" "spoke-vnet-rg" {
  name     = local.spoke-resource-group
  location = local.spoke-location
}

resource "azurerm_virtual_network" "spoke-vnet" {
  name                = "spoke-vnet"
  location            = azurerm_resource_group.spoke-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-vnet-rg.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    environment = local.prefix-spoke
  }
}

resource "azurerm_subnet" "spoke-mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.spoke-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.spoke-vnet.name
  address_prefix       = "10.1.0.64/27"
}

resource "azurerm_virtual_network_peering" "spoke-hub-peer" {
  name                      = "spoke-hub-peer"
  resource_group_name       = azurerm_resource_group.spoke-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = true
  depends_on = [azurerm_virtual_network.spoke-vnet, azurerm_virtual_network.hub-vnet , azurerm_virtual_network_gateway.hub-vnet-gateway]
}

resource "azurerm_network_interface" "az-mgmt-nic" {
  name                 = "az-mgmt-nic"
  location             = azurerm_resource_group.spoke-vnet-rg.location
  resource_group_name  = azurerm_resource_group.spoke-vnet-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = local.prefix-spoke
    subnet_id                     = azurerm_subnet.spoke-mgmt.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "az-mgmt-vm" {
  name                  = "az-mgmt-vm"
  location              = azurerm_resource_group.spoke-vnet-rg.location
  resource_group_name   = azurerm_resource_group.spoke-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.az-mgmt-nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-mgmt-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-spoke}-vm"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    environment = local.prefix-spoke
  }
}

resource "azurerm_virtual_network_peering" "hub-spoke-peer" {
  name                      = "hub-spoke-peer"
  resource_group_name       = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
  depends_on = [azurerm_virtual_network.spoke-vnet, azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vnet-gateway]
}