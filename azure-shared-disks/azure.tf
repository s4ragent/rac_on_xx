# Configure the Microsoft Azure Provider
#
provider "azurerm" {
        features {}
}

variable "db_servers" {
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
  name                  = local.yaml.SCAN_NAME
  zone_name           = azurerm_private_dns_zone.racdns.name
  resource_group_name = azurerm_resource_group.racgroup.name
  ttl                 = 300
  records             = ["${local.network}${local.common_yaml.BASE_IP -20 }","${local.network}${local.common_yaml.BASE_IP -20 +1}","${local.network}${local.common_yaml.BASE_IP -20 +2}"]
}

###########Azure Private DNS #############



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
    allocation_method            = "Static"
    sku                          = "Standard"
    zones                = ["${local.yaml.zone}"]
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

    zone = local.yaml.zone
    
    additional_capabilities {
       ultra_ssd_enabled = true
    }
        
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
    zones                = ["${local.yaml.zone}"]
}

resource "azurerm_virtual_machine_data_disk_attachment" "db_data_disk_attach" {
  count              = var.db_servers
  managed_disk_id    = element(azurerm_managed_disk.db_data_disk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.dbvm.*.id, count.index)
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
    allocation_method            = "Static"
    sku                          = "Standard"
    zones                = ["${local.yaml.zone}"]
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
    zone = local.yaml.zone

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
    zones                = ["${local.yaml.zone}"]
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


######ultra disk ####
resource "azurerm_managed_disk" "ultra_disk_vote" {
    name                  = "ultra_disk_vote"
    location              = local.yaml.location
    zones                = ["${local.yaml.zone}"]
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = "UltraSSD_LRS"
    create_option        = "Empty"
    disk_size_gb         = local.yaml.VOTE_SIZE
    disk_iops_read_write = local.yaml.disk_iops_read_write
    disk_mbps_read_write = local.yaml.disk_mbps_read_write    
     
    provisioner "local-exec" {
      command = "az disk update --resource-group ${azurerm_resource_group.racgroup.name} --name ultra_disk_vote --set maxShares=5"
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "ultra_disk_vote_attach" {
  count              = var.db_servers
  managed_disk_id    = azurerm_managed_disk.ultra_disk_vote.id
  virtual_machine_id = element(azurerm_linux_virtual_machine.dbvm.*.id, count.index)
  caching            = "None"
  lun                = "20"
}

resource "azurerm_managed_disk" "ultra_disk_data" {
    name                  = "ultra_disk_data"
    location              = local.yaml.location
    zones                = ["${local.yaml.zone}"]
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = "UltraSSD_LRS"
    create_option        = "Empty"
    disk_size_gb         = local.yaml.DATA_SIZE
    disk_iops_read_write = local.yaml.disk_iops_read_write
    disk_mbps_read_write = local.yaml.disk_mbps_read_write
     
    provisioner "local-exec" {
      command = "az disk update --resource-group ${azurerm_resource_group.racgroup.name} --name ultra_disk_data --set maxShares=5"
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "ultra_disk_data_attach" {
  count              = var.db_servers
  managed_disk_id    = azurerm_managed_disk.ultra_disk_data.id
  virtual_machine_id = element(azurerm_linux_virtual_machine.dbvm.*.id, count.index)
  caching            = "None"
  lun                = "30"
}

resource "azurerm_managed_disk" "ultra_disk_fra" {
    name                  = "ultra_disk_fra"
    location              = local.yaml.location
    zones                = ["${local.yaml.zone}"]
    resource_group_name   = azurerm_resource_group.racgroup.name
    storage_account_type = "UltraSSD_LRS"
    create_option        = "Empty"
    disk_size_gb         = local.yaml.FRA_SIZE
    disk_iops_read_write = local.yaml.disk_iops_read_write
    disk_mbps_read_write = local.yaml.disk_mbps_read_write
     
    provisioner "local-exec" {
      command = "az disk update --resource-group ${azurerm_resource_group.racgroup.name} --name ultra_disk_fra --set maxShares=5"
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "ultra_disk_fra_attach" {
  count              = var.db_servers
  managed_disk_id    = azurerm_managed_disk.ultra_disk_fra.id
  virtual_machine_id = element(azurerm_linux_virtual_machine.dbvm.*.id, count.index)
  caching            = "None"
  lun                = "40"
}
