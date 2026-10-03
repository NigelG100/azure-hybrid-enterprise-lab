terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "admin_password" {
  description = "Local Windows administrator password"
  type        = string
  sensitive   = true
}

# Existing Project 1 network
data "azurerm_virtual_network" "existing" {
  name                = "vnet-secure-infra"
  resource_group_name = "rg-secure-infra"
}

# Separate resource group for Project 2
resource "azurerm_resource_group" "hybrid" {
  name     = "rg-hybrid-lab"
  location = "eastus"
}

# Windows infrastructure subnet
resource "azurerm_subnet" "windows" {
  name                 = "snet-windows"
  resource_group_name  = "rg-secure-infra"
  virtual_network_name = data.azurerm_virtual_network.existing.name
  address_prefixes     = ["10.20.10.0/24"]
}

# Windows security group
resource "azurerm_network_security_group" "windows" {
  name                = "nsg-windows"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name

  security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.20.20.0/26"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Other-VNet-RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "windows" {
  subnet_id                 = azurerm_subnet.windows.id
  network_security_group_id = azurerm_network_security_group.windows.id
}

# Domain controller network interface
resource "azurerm_network_interface" "dc" {
  name                = "nic-dc01"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.10.10"
  }
}

# Windows Server 2022
resource "azurerm_windows_virtual_machine" "dc" {
  name                = "dc01"
  resource_group_name = azurerm_resource_group.hybrid.name
  location            = azurerm_resource_group.hybrid.location

  size           = "Standard_D2as_v4"
  admin_username = "labadmin"
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.dc.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}