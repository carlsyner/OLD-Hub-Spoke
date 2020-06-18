locals {
  prefix-hub         = "hub"
  hub-location       = var.location
  hub-resource-group = "private-endpoint-openhack-hub-rg"
  shared-key         = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

#######################################################################
## Create Resource Groups
#######################################################################

resource "azurerm_resource_group" "hub-vnet-rg" {
  name     = local.hub-resource-group
  location = local.hub-location
}

#######################################################################
## Create Virtual Networks
#######################################################################

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "hub-spoke"
  }
}

#######################################################################
## Create Subnets
#######################################################################

resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefix       = "10.0.255.224/27"
}

resource "azurerm_subnet" "hub-dc" {
  name                 = "dc"
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefix       = "10.0.0.32/27"
}

#######################################################################
## Create Network Interface
#######################################################################

resource "azurerm_network_interface" "az-dc-nic" {
  name                 = "az-dc-nic"
  location             = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = local.prefix-hub
    subnet_id                     = azurerm_subnet.hub-dc.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.prefix-hub
  }
}

#######################################################################
## Create Virtual Machine
#######################################################################

resource "azurerm_virtual_machine" "az-dc-vm" {
  name                  = "az-dc-vm"
  location              = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name   = azurerm_resource_group.hub-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.az-dc-nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-dc-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "az-dc-vm"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

   tags = {
    environment = local.prefix-hub
  }
}

#############################################################################
## Create Virtual Network Gateway
#############################################################################

resource "azurerm_public_ip" "hub-vpn-gateway-pip" {
  name                = "hub-vpn-gateway-pip"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
  name                = "hub-vpn-gateway"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub-vpn-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
  }
  depends_on = [azurerm_public_ip.hub-vpn-gateway-pip]
}

#######################################################################
## Create Connections
#######################################################################

resource "azurerm_virtual_network_gateway_connection" "hub-onprem-conn" {
  name                = "hub-onprem-conn"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  type           = "Vnet2Vnet"
  routing_weight = 1

  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub-vnet-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem-vpn-gateway.id

  shared_key = local.shared-key
}

resource "azurerm_virtual_network_gateway_connection" "onprem-hub-conn" {
  name                = "onprem-hub-conn"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name
  type                            = "Vnet2Vnet"
  routing_weight = 1
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem-vpn-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub-vnet-gateway.id

  shared_key = local.shared-key
}