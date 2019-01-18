# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "vm" {
    name     = "rg-${var.suffix}"
    location = "${var.location}"
}

# Create virtual network
resource "azurerm_virtual_network" "vm" {
    name                = "vnet-${var.suffix}"
    address_space       = ["${var.vnet_addr}"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vm.name}"
}

# Create subnet
resource "azurerm_subnet" "vm" {
    name                 = "subnet-${var.suffix}"
    resource_group_name  = "${azurerm_resource_group.vm.name}"
    virtual_network_name = "${azurerm_virtual_network.vm.name}"
    address_prefix       = "${var.snet_addr}"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm" {
    name                = "nsg-${var.suffix}"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vm.name}"

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

resource "azurerm_virtual_machine" "node" {
  count                         = "${var.nb_instances}"
  name                          = "${format("${var.NODEPREFIX}%03d", count.index + 1)}"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.vm.name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  delete_os_disk_on_termination = "false"

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer     = "${var.vm_os_offer}"
    sku       = "${var.vm_os_sku}"
    version   = "${var.vm_os_version}"
  }

  storage_os_disk {
    name              = "osdisk-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "${var.storage_account_type}"
  }

  storage_data_disk {
    name              = "datadisk-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "${format("${var.NODEPREFIX}%03d", count.index + 1)}"
    admin_username = "${var.ansible_ssh_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.ansible_ssh_user}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }
}

resource "azurerm_public_ip" "node" {
  count                        = "${var.nb_instances}"
  name                         = "${format("${var.NODEPREFIX}%03d", count.index + 1)}-publicIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.vm.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "node" {
  count                     = "${var.nb_instances}"
  name                      = "nic-${format("${var.NODEPREFIX}%03d", count.index + 1)}"
  location                  = "${azurerm_resource_group.vm.location}"
  resource_group_name       = "${azurerm_resource_group.vm.name}"
  network_security_group_id = "${azurerm_network_security_group.vm.id}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${azurerm_subnet.vm.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${length(azurerm_public_ip.vm.*.id) > 0 ? element(concat(azurerm_public_ip.node.*.id, list("")), count.index) : ""}"
  }
}

resource "azurerm_virtual_machine" "storage" {
  count                         = "1"
  name                          = "storage"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.vm.name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${azurerm_network_interface.storage.id}"]
  delete_os_disk_on_termination = "false"

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer     = "${var.vm_os_offer}"
    sku       = "${var.vm_os_sku}"
    version   = "${var.vm_os_version}"
  }

  storage_os_disk {
    name              = "osdisk-storage"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "${var.storage_account_type}"
  }

  storage_data_disk {
    name              = "datadisk-storage"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "storage"
    admin_username = "${var.ansible_ssh_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.ansible_ssh_user}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }
}

resource "azurerm_public_ip" "storage" {
  count                        = "1"
  name                         = "storage-publicIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.vm.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "storage" {
  count                         = "${var.nb_instances}"
  name                          = "nic-storage"
  location                      = "${azurerm_resource_group.vm.location}"
  resource_group_name           = "${azurerm_resource_group.vm.name}"
  network_security_group_id     = "${azurerm_network_security_group.vm.id}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.vm.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.node.id}"
  }
}
