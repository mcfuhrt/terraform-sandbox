provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraform" {
  name     = var.resource_group_name
  location = "West Europe"
}

module "website_s3_bucket" {
  source              = "../modules/azure-secured-vm"
  resource_group_name = azurerm_resource_group.terraform.name
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  #nsg_ids = {
  #  subnet1 = azurerm_network_security_group.vnet.id
  #}


  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  depends_on = [azurerm_resource_group.terraform]
}

/*
module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.terraform.name
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  nsg_ids = {
    subnet1 = azurerm_network_security_group.ssh.id
  }


  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  depends_on = [azurerm_resource_group.terraform]
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "myTFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
*/

/*
resource "azurerm_subnet" "subnet" {
  count                                          = length(var.subnet_names)
  name                                           = var.subnet_names[count.index]
  resource_group_name                            = data.azurerm_resource_group.vnet.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [var.subnet_prefixes[count.index]]
  service_endpoints                              = lookup(var.subnet_service_endpoints, var.subnet_names[count.index], null)
  enforce_private_link_endpoint_network_policies = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.subnet_names[count.index], false)
  enforce_private_link_service_network_policies  = lookup(var.subnet_enforce_private_link_service_network_policies, var.subnet_names[count.index], false)
}
*/

/*
# Public IP address
resource "azurerm_public_ip" "public_ip" {
  name                = "rg-pip"
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location
  allocation_method   = "Static"
}

# Network interface
resource "azurerm_network_interface" "network_interface" {
  name                = "example-nic"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Network security group
resource "azurerm_network_security_group" "ssh" {
  name                = join("", ["terraform", "NSG"])
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location

  security_rule {
    name                       = "default-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["91.249.132.105", "91.249.147.22", "91.249.171.114", "91.249.171.115"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "default-allow-api"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8001"
    source_address_prefixes    = ["52.233.251.124"]
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}
*/