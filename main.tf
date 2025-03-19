# Definición del provider que ocuparemos
provider "azurerm" {
  features {}
  subscription_id = "dad0afe0-0559-43a5-9469-edf299dd150a"
}

resource "azurerm_resource_group" "miprimeravmrg" {
  name     = "miprimeravmrg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "miprimeravmvnet" {
  name                = "miprimeravmvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.miprimeravmrg.location
  resource_group_name = azurerm_resource_group.miprimeravmrg.name
}

resource "azurerm_subnet" "miprimeravmsubnet" {
  name                 = "miprimeravmsubnet"
  resource_group_name  = azurerm_resource_group.miprimeravmrg.name
  virtual_network_name = azurerm_virtual_network.miprimeravmvnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "miprimeravmnic" {
  name                = "miprimeravmnic"
  location            = azurerm_resource_group.miprimeravmrg.location
  resource_group_name = azurerm_resource_group.miprimeravmrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.miprimeravmsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.miprimeravmpublicip.id
  }
}

resource "azurerm_linux_virtual_machine" "miprimeravm" {
  name                = "miprimeravm"
  resource_group_name = azurerm_resource_group.miprimeravmrg.name
  location            = azurerm_resource_group.miprimeravmrg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Password*#123"
  network_interface_ids = [
    azurerm_network_interface.miprimeravmnic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  disable_password_authentication = false
  provision_vm_agent              = true
}

resource "azurerm_network_security_group" "miprimeravmnsg" {
  name                = "miprimeravmnsg"
  location            = azurerm_resource_group.miprimeravmrg.location
  resource_group_name = azurerm_resource_group.miprimeravmrg.name

  security_rule {
    name                       = "ssh_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "miprimeravmnicnsg" {
  network_interface_id      = azurerm_network_interface.miprimeravmnic.id
  network_security_group_id = azurerm_network_security_group.miprimeravmnsg.id
}

resource "azurerm_public_ip" "miprimeravmpublicip" {
  name                = "miprimeravmpublicip"
  location            = azurerm_resource_group.miprimeravmrg.location
  resource_group_name = azurerm_resource_group.miprimeravmrg.name
  allocation_method   = "Static"
}