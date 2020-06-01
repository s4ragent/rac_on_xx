# Configure the Microsoft Azure Provider
provider "azurerm" {
        features {}
}

locals{ 
        yaml = yamldecode(file("./vars.yml"))
}


# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "vm" {
    name     = "rg-${local.yaml.suffix}"
    location = "local.yaml.ZONE"
}

# Create virtual network
resource "azurerm_virtual_network" "vm" {
    name                = "vnet-${local.yaml.suffix}"
    address_space       = ["local.yaml.vnet_addr"]
    location            = "local.yaml.location"
    resource_group_name = "azurerm_resource_group.vm.name"
}

# Create subnet
resource "azurerm_subnet" "vm" {
    name                 = "subnet-${local.yaml.suffix}"
    resource_group_name  = "azurerm_resource_group.vm.name"
    virtual_network_name = "azurerm_virtual_network.vm.name"
    address_prefixes       = ["local.yaml.snet_addr"]
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm" {
    name                = "nsg-${local.yaml.suffix}"
    location            = "local.yaml.location"
    resource_group_name = "azurerm_resource_group.vm.name"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}


