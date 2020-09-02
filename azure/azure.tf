# Configure the Microsoft Azure Provider
provider "azurerm" {
        features {}
}

variable "db_servers" {
}

variable "storage_servers" {
}

variable "client_servers" {
}

locals{ 
        yaml = yamldecode(file("./vars.yml"))
        common_yaml =  yamldecode(file("../common_vars.yml"))
        network = "${element(split(".", local.common_yaml.vxlan0_NETWORK), 0)}.${element(split(".", local.common_yaml.vxlan0_NETWORK), 1)}.${element(split(".", local.common_yaml.vxlan0_NETWORK), 2)}."
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



###########Azure Private DNS #############

# Create a zone if it doesn't exist
resource "azurerm_private_dns_zone" "racdns" {
  name                = local.yaml.DOMAIN_NAME
  resource_group_name = azurerm_resource_group.racgroup.name
}

# create virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "racvirtnetworklink" {
  name                  = "racvirtnetworklink"
  resource_group_name   = azurerm_resource_group.racgroup.name
  private_dns_zone_name = azurerm_private_dns_zone.racdns.name
  virtual_network_id    = azurerm_virtual_network.racnetwork.id
}

# Create a record if it doesn't exist
resource "azurerm_private_dns_a_record" "racrecord" {
  count                 = var.db_servers
  name                  = format("${local.yaml.NODEPREFIX}%03d", count.index + 1)
  zone_name           = azurerm_private_dns_zone.racdns.name
  resource_group_name = azurerm_resource_group.racgroup.name
  ttl                 = 300
  records             = ["${local.network}${count.index + local.common_yaml.BASE_IP + 1}"]
}

# Create a vip record if it doesn't exist
resource "azurerm_private_dns_a_record" "racviprecord" {
  count                 = var.db_servers
  name                  = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}-vip"
  zone_name           = azurerm_private_dns_zone.racdns.name
  resource_group_name = azurerm_resource_group.racgroup.name
  ttl                 = 300
  records             = ["${local.network}${count.index + local.common_yaml.BASE_IP + 1 + 100}"]
}

# Create a scan record if it doesn't exist
resource "azurerm_private_dns_a_record" "racscanrecord" {
  count                 = 3
  name                  = local.yaml.SCAN_NAME
  zone_name           = azurerm_private_dns_zone.racdns.name
  resource_group_name = azurerm_resource_group.racgroup.name
  ttl                 = 300
  records             = ["${local.network}${count.index + local.common_yaml.BASE_IP -20 }"]
}

###########Azure Private DNS #############


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
    name                      = "nic-${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
    location                  = local.yaml.location
    resource_group_name       = azurerm_resource_group.racgroup.name
    
    enable_accelerated_networking = local.yaml.enable_accelerated_networking

    ip_configuration {
        name                          = "ipconfigdb${count.index}"
        subnet_id                     = azurerm_subnet.racsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.racdbip.*.id, count.index) 
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
    name                  = format("${local.yaml.NODEPREFIX}%03d", count.index + 1)
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    network_interface_ids = [element(azurerm_network_interface.racdbnic.*.id, count.index)]
    size                  = local.yaml.db_vm_size

    os_disk {
        name              = "osdisk-${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
        caching           = "ReadWrite"
        storage_account_type = local.yaml.storage_account_type
    }

    source_image_reference {
        publisher = local.yaml.vm_os_publisher
        offer     = local.yaml.vm_os_offer
        sku       = local.yaml.vm_os_sku
        version   = local.yaml.vm_os_version
    }

    computer_name  = "${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}.${local.yaml.DOMAIN_NAME}"
    admin_username = local.yaml.ansible_ssh_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = local.yaml.ansible_ssh_user
        public_key     = file("../${local.yaml.ansible_ssh_private_key_file}.pub")
    }
}

resource "azurerm_managed_disk" "db_data_disk" {
    count                 = var.db_servers
    name                  = "datadisk-${format("${local.yaml.NODEPREFIX}%03d", count.index + 1)}"
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = local.yaml.storage_account_type
    create_option        = "Empty"
    disk_size_gb         = local.yaml.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "db_data_disk_attach" {
  count              = var.db_servers
  managed_disk_id    = element(azurerm_managed_disk.db_data_disk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.dbvm.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

##storage
# Create public IPs
resource "azurerm_public_ip" "racstorageip" {
    count                        = var.storage_servers
    name                         = "${format("storage%03d", count.index + 1)}-publicIP"
    location                     = local.yaml.location
    resource_group_name          = azurerm_resource_group.racgroup.name
    allocation_method            = "Dynamic"
}


# Create network interface
resource "azurerm_network_interface" "racstoragenic" {
    count                     = var.storage_servers
    name                      = "nic-${format("storage%03d", count.index + 1)}"
    location                  = local.yaml.location
    resource_group_name       = azurerm_resource_group.racgroup.name
    
    enable_accelerated_networking = local.yaml.enable_accelerated_networking

    ip_configuration {
        name                          = "ipconfigstorage${count.index}"
        subnet_id                     = azurerm_subnet.racsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.racstorageip.*.id, count.index) 
    }
}

resource "azurerm_network_interface_security_group_association" "attach_storagenic_Nsg" {
    count                     = var.storage_servers
    network_interface_id      = element(azurerm_network_interface.racstoragenic.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.racnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "storagevm" {
    count                 = var.storage_servers
    name                  = format("storage%03d", count.index + 1)
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    network_interface_ids = [element(azurerm_network_interface.racstoragenic.*.id, count.index)]
    size                  = local.yaml.storage_vm_size

    os_disk {
        name              = "osdisk-${format("storage%03d", count.index + 1)}"
        caching           = "ReadWrite"
        storage_account_type = local.yaml.storage_account_type
    }

    source_image_reference {
        publisher = local.yaml.vm_os_publisher
        offer     = local.yaml.vm_os_offer
        sku       = local.yaml.vm_os_sku
        version   = local.yaml.vm_os_version
    }

    computer_name  = "${format("storage%03d", count.index + 1)}.${local.yaml.DOMAIN_NAME}"
    admin_username = local.yaml.ansible_ssh_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = local.yaml.ansible_ssh_user
        public_key     = file("../${local.yaml.ansible_ssh_private_key_file}.pub")
    }
}

resource "azurerm_managed_disk" "storage_data_disk" {
    count                 = var.storage_servers
    name                  = "datadisk-${format("storage%03d", count.index + 1)}"
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = local.yaml.storage_account_type
    create_option        = "Empty"
    disk_size_gb         = local.yaml.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "storage_data_disk_attach" {
  count              = var.storage_servers
  managed_disk_id    = element(azurerm_managed_disk.storage_data_disk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.storagevm.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}


###client####
##client
# Create public IPs
resource "azurerm_public_ip" "racclientip" {
    count                        = var.client_servers
    name                         = "${format("client%03d", count.index + 1)}-publicIP"
    location                     = local.yaml.location
    resource_group_name          = azurerm_resource_group.racgroup.name
    allocation_method            = "Dynamic"
}


# Create network interface
resource "azurerm_network_interface" "racclientnic" {
    count                     = var.client_servers
    name                      = "nic-${format("client%03d", count.index + 1)}"
    location                  = local.yaml.location
    resource_group_name       = azurerm_resource_group.racgroup.name
    
    enable_accelerated_networking = local.yaml.enable_accelerated_networking

    ip_configuration {
        name                          = "ipconfigclient${count.index}"
        subnet_id                     = azurerm_subnet.racsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.racclientip.*.id, count.index) 
    }
}

resource "azurerm_network_interface_security_group_association" "attach_clientnic_Nsg" {
    count                     = var.client_servers
    network_interface_id      = element(azurerm_network_interface.racclientnic.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.racnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "clientvm" {
    count                 = var.client_servers
    name                  = format("client%03d", count.index + 1)
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    network_interface_ids = [element(azurerm_network_interface.racclientnic.*.id, count.index)]
    size                  = local.yaml.client_vm_size

    os_disk {
        name              = "osdisk-${format("client%03d", count.index + 1)}"
        caching           = "ReadWrite"
        storage_account_type = local.yaml.storage_account_type
    }

    source_image_reference {
        publisher = local.yaml.vm_os_publisher
        offer     = local.yaml.vm_os_offer
        sku       = local.yaml.vm_os_sku
        version   = local.yaml.vm_os_version
    }

    computer_name  = "${format("client%03d", count.index + 1)}.${local.yaml.DOMAIN_NAME}"
    admin_username = local.yaml.ansible_ssh_user
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = local.yaml.ansible_ssh_user
        public_key     = file("../${local.yaml.ansible_ssh_private_key_file}.pub")
    }
}

resource "azurerm_managed_disk" "client_data_disk" {
    count                 = var.client_servers
    name                  = "datadisk-${format("client%03d", count.index + 1)}"
    location              = local.yaml.location
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = local.yaml.storage_account_type
    create_option        = "Empty"
    disk_size_gb         = local.yaml.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "client_data_disk_attach" {
  count              = var.client_servers
  managed_disk_id    = element(azurerm_managed_disk.client_data_disk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.clientvm.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}


