locals {
  onprem-location       = var.onpremlocation
  onprem-resource-group = "private-endpoint-openhack-onprem-rg"
  prefix-onprem         = "onprem"
}

#######################################################################
## Create Resource Group
#######################################################################

resource "azurerm_resource_group" "onprem-vnet-rg" {
  name     = local.onprem-resource-group
  location = local.onprem-location
}

#######################################################################
## Create Virtual Network
#######################################################################

resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name
  address_space       = ["192.168.0.0/16"]

  tags = {
    environment = local.prefix-onprem
  }
}

#######################################################################
## Create Subnets
#######################################################################

resource "azurerm_subnet" "onprem-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefix       = "192.168.255.224/27"
}

resource "azurerm_subnet" "onprem-mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefix       = "192.168.1.128/25"
}

resource "azurerm_subnet" "onprem-dc" {
  name                 = "dc"
  resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefix       = "192.168.2.0/27"
}

#######################################################################
## Create Public IPs
#######################################################################

resource "azurerm_public_ip" "onprem-mgmt-pip" {
    name                 = "onprem-mgmt-pip"
    location            = azurerm_resource_group.onprem-vnet-rg.location
    resource_group_name = azurerm_resource_group.onprem-vnet-rg.name
    allocation_method   = "Dynamic"

    tags = {
        environment = local.prefix-onprem
    }
}

#######################################################################
## Create Network Interfaces
#######################################################################

resource "azurerm_network_interface" "onprem-mgmt-nic" {
  name                 = "onprem-mgmt-nic"
  location             = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = local.prefix-onprem
    subnet_id                     = azurerm_subnet.onprem-mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onprem-mgmt-pip.id
  }
}

resource "azurerm_network_interface" "onprem-dc-nic" {
  name                 = "onprem-dc-nic"
  location             = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = local.prefix-onprem
    subnet_id                     = azurerm_subnet.onprem-dc.id
    private_ip_address_allocation = "Dynamic"
  }
}

##########################################################
## Create Network Security Group and rule
###########################################################

resource "azurerm_network_security_group" "onprem-mgmt-nsg" {
    name                = "onprem-mgmt-nsg"
    location            = azurerm_resource_group.onprem-vnet-rg.location
    resource_group_name = azurerm_resource_group.onprem-vnet-rg.name

    security_rule {
        name                       = "Allow_RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
      source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "onprem"
    }
}

resource "azurerm_subnet_network_security_group_association" "mgmt-nsg-association" {
  subnet_id                 = azurerm_subnet.onprem-mgmt.id
  network_security_group_id = azurerm_network_security_group.onprem-mgmt-nsg.id
}

#######################################################################
## Create Virtual Machines
#######################################################################

resource "azurerm_virtual_machine" "onprem-mgmt-vm" {
  name                  = "onprem-mgmt-vm"
  location              = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name   = azurerm_resource_group.onprem-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.onprem-mgmt-nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "onprem-mgmt-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "onprem-mgmt-vm"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    environment = local.prefix-onprem
  }
}

resource "azurerm_virtual_machine" "onprem-dc-vm" {
  name                  = "onprem-dc-vm"
  location              = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name   = azurerm_resource_group.onprem-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.onprem-dc-nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "onprem-dc-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "onprem-dc-vm"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    environment = local.prefix-onprem
  }
}

#######################################################################
## Create Virtual Network Gateway
#######################################################################

resource "azurerm_public_ip" "onprem-vpn-gateway-pip" {
  name                = "${local.prefix-onprem}-vpn-gateway-pip"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
  name                = "onprem-vpn-gateway"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem-vpn-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onprem-gateway-subnet.id
  }
  depends_on = [azurerm_public_ip.onprem-vpn-gateway-pip]

}