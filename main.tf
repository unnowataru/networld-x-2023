provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

resource "azurerm_resource_group" "aigen_rg" {
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_virtual_network" "aigen_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.aigen_rg.name
  location            = var.region
  address_space       = [var.vnet_range]
}

resource "azurerm_subnet" "aigen_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.aigen_rg.name
  virtual_network_name = azurerm_virtual_network.aigen_vnet.name
  address_prefixes     = [var.subnet_range]
}

resource "azurerm_network_security_group" "aigen_nsg" {
  name                = var.nsg_name
  location            = var.region
  resource_group_name = azurerm_resource_group.aigen_rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "aigen_nic" {
  name                = var.nic_name
  location            = var.region
  resource_group_name = azurerm_resource_group.aigen_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.aigen_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aigen_pip.id
  }
}

resource "azurerm_public_ip" "aigen_pip" {
  name                = var.pip_name
  location            = var.region
  resource_group_name = azurerm_resource_group.aigen_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_windows_virtual_machine" "aigen_vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.aigen_rg.name
  location            = var.region
  size                = var.vm_size
  network_interface_ids = [azurerm_network_interface.aigen_nic.id]
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
