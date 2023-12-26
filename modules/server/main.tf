data "onepassword_vault" "vault" {
  name = "minecraft-servers"
}

data "onepassword_item" "secrets" {
  vault = data.onepassword_vault.vault.uuid
  title = "setup"
}

output "secrets" {
  value = data.onepassword_item.secrets
}

locals {
  secrets = {
    for e in one(data.onepassword_item.secrets.section).field :
    e.label => e.value
  }

  az_service_principal = jsondecode(local.secrets["az_service_principal_json"])
}

# generate random username and password
resource "random_string" "vm_username" {
  length  = 10
  special = false
  upper   = false
  numeric = false
}

resource "tls_private_key" "vm_public_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "onepassword_item" "generated_secrets" {
  vault    = data.onepassword_vault.vault.uuid
  title    = var.name
  category = "password"
  section {
    label = ""
    field {
      label = "public_ip_address"
      value = azurerm_public_ip.public_ip.ip_address
    }
    field {
      label = "vm_username"
      value = random_string.vm_username.result
    }
    field {
      label = "vm_private_key"
      value = tls_private_key.vm_public_key.private_key_pem
    }
    field {
      label = "vm_public_key"
      value = tls_private_key.vm_public_key.public_key_openssh
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "minecraft-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "minecraft-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP address
resource "azurerm_public_ip" "public_ip" {
  name                = "minecraft-publicip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# Create a network security group and associate it with the virtual machine's network interface
resource "azurerm_network_security_group" "nsg" {
  name                = "minecraft-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "allow_minecraft" {
  name                        = "allow-minecraft"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "19132"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create a network interface and associate it with the subnet and public IP address
resource "azurerm_network_interface" "nic" {
  name                = "minecraft-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "minecraft-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "server" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = random_string.vm_username.result
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = random_string.vm_username.result
    public_key = tls_private_key.vm_public_key.public_key_openssh
  }

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
}

# Output the public IP address of the virtual machine
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "vm" {
  value = azurerm_linux_virtual_machine.server
}
