variable "member_admin_password" {
  description = "Local administrator password for MEMBER01"
  type        = string
  sensitive   = true
}

# Network interface for MEMBER01
resource "azurerm_network_interface" "member" {
  name                = "nic-member01"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name

  # Use our domain controller for DNS
  dns_servers = ["10.20.10.10"]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.10.20"
  }
}

# Windows domain member VM
resource "azurerm_windows_virtual_machine" "member" {
  name                = "member01"
  computer_name       = "MEMBER01"
  resource_group_name = azurerm_resource_group.hybrid.name
  location            = azurerm_resource_group.hybrid.location

  size           = "Standard_D2as_v4"
  admin_username = "labadmin"
  admin_password = var.member_admin_password

  network_interface_ids = [
    azurerm_network_interface.member.id
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
