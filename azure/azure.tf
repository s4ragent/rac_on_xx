# Configure the Microsoft Azure Provider
provider "azurerm" {
        features {}
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
    count                        = "${var.db_servers}"
    name                         = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}-publicIP"
    location                     = local.yaml.location
    resource_group_name          = azurerm_resource_group.racgroup.name
    allocation_method            = "Dynamic"
}


# Create network interface
resource "azurerm_network_interface" "racdbnic" {
    count                     = "${var.db_servers}"
    name                      = "nic-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
    location                  = local.yaml.location
    resource_group_name       = azurerm_resource_group.racgroup.name

    ip_configuration {
        name                          = "ipconfigdb${count.index}"
        subnet_id                     = azurerm_subnet.racsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = public_ip_address_id = "${element(azurerm_public_ip.racdbip.*.id, count.index)}" 
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "racdbassciate" {
    network_interface_id      = azurerm_network_interface.racdbnic.id
    network_security_group_id = azurerm_network_security_group.racnsg".id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "dbvm" {
    count                 = "${var.db_servers}"
    name                  = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "azureuser"
        public_key     = file("/home/azureuser/.ssh/authorized_keys")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}
