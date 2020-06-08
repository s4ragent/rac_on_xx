# Configure the Microsoft Azure Provider
provider "azurerm" {
        features {}
}

variable "db_servers" {
}

locals{ 
        yaml = yamldecode(file("./vars.yml"))
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "racgroup" {
    name     = "rg-${local.yaml.suffix}"
    location = local.yaml.location
}

# Create virtual network
resource "azurerm_virtual_network" "racnetwork" {
    name = "vnet-${local.yaml.suffix}"
    location = local.yaml.location
    address_space       = [local.yaml.vnet_addr]
    resource_group_name = azurerm_resource_group.racgroup.name
}

# Create subnet
resource "azurerm_subnet" "racsubnet" {
    name                 = "subnet-${local.yaml.suffix}"
    resource_group_name  = azurerm_resource_group.racgroup.name
    virtual_network_name = azurerm_virtual_network.racnetwork.name
    address_prefixes       = [local.yaml.snet_addr]
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "racnsg" {
    name                = "nsg-${local.yaml.suffix}"
    location            = local.yaml.location
    resource_group_name = azurerm_resource_group.racgroup.name
    
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


# Create public IPs
resource "azurerm_public_ip" "racdbip" {
    count                        = var.db_servers
    name                         = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}-publicIP"
    location                     = local.yaml.location
    resource_group_name          = azurerm_resource_group.racgroup.name
    allocation_method            = "Dynamic"
}


# Create network interface
resource "azurerm_network_interface" "racdbnic" {
    count                     = var.db_servers
    name                      = "nic-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
    location                  = local.yaml.location
    resource_group_name       = azurerm_resource_group.racgroup.name

    ip_configuration {
        name                          = "ipconfigdb${count.index}"
        subnet_id                     = azurerm_subnet.racsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.racdbip.*.id, count.index)}" 
    }
}

resource "azurerm_network_interface_security_group_association" "attach_dbnic_Nsg" {
    count                     = var.db_servers
    network_interface_id      = element(azurerm_network_interface.racdbnic.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.racnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "dbvm" {
    count                 = var.db_servers
    name                  = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    network_interface_ids = ["${element(azurerm_network_interface.racdbnic.*.id, count.index)}"]
    size                  = local.yaml.vm_size

    os_disk {
        name              = "osdisk-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
        caching           = "ReadWrite"
        storage_account_type = local.yaml.storage_account_type
    }

    source_image_reference {
        publisher = local.yaml.vm_os_publisher
        offer     = local.yaml.vm_os_offer
        sku       = local.yaml.vm_os_sku
        version   = local.yaml.vm_os_version
    }


    computer_name  = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
    admin_username = local.yaml.ansible_ssh_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = local.yaml.ansible_ssh_user
        public_key     = file(local.yaml.ansible_ssh_private_key_file)
    }

}
