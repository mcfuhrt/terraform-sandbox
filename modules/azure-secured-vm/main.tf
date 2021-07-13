#Azure Generic vNet Module
data azurerm_resource_group "vm" {
  name = var.resource_group_name
}

# Virtual Network
resource azurerm_virtual_network "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = var.vnet_location != null ? var.vnet_location : data.azurerm_resource_group.vm.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "subnet" {
  count                                          = length(var.subnet_names)
  name                                           = var.subnet_names[count.index]
  resource_group_name                            = data.azurerm_resource_group.vm.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [var.subnet_prefixes[count.index]]
  service_endpoints                              = lookup(var.subnet_service_endpoints, var.subnet_names[count.index], null)
  enforce_private_link_endpoint_network_policies = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.subnet_names[count.index], false)
  enforce_private_link_service_network_policies  = lookup(var.subnet_enforce_private_link_service_network_policies, var.subnet_names[count.index], false)
}

/*
resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each                  = var.nsg_ids
  subnet_id                 = local.azurerm_subnets[each.key]
  network_security_group_id = each.value
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each       = var.route_tables_ids
  route_table_id = each.value
  subnet_id      = local.azurerm_subnets[each.key]
}
*/

# Public IP address
resource "azurerm_public_ip" "vnet" {
  name                = "rg-pip"
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location
  allocation_method   = "Static"
}

# Network interface
resource "azurerm_network_interface" "vnet" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.vm.location
  resource_group_name = data.azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet[0].id#[count.index].id#azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vnet.id
  }
}

# Network security group
resource "azurerm_network_security_group" "vnet" {
  name                = join("", ["terraform", "NSG"])
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location

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

resource "azurerm_network_interface_security_group_association" "vnet" {
  network_interface_id      = azurerm_network_interface.vnet.id
  network_security_group_id = azurerm_network_security_group.vnet.id
}

# Virtual machine
resource "azurerm_linux_virtual_machine" "vnet" {
  name                            = "example-machine"
  resource_group_name             = data.azurerm_resource_group.vm.name
  location                        = data.azurerm_resource_group.vm.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vnet.id,
  ]

  #admin_ssh_key {
  #  username   = "adminuser"
  #  public_key = file("~/.ssh/id_rsa.pub")
  #}

  # Disk
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}