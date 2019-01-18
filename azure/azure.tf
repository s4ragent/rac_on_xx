# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "vm" {
    name     = "rg-$(var.suffix)"
    location = "${var.location}"
}

# Create virtual network
resource "azurerm_virtual_network" "vm" {
    name                = "vnet-$(var.suffix)"
    address_space       = ["$(var.vnet_addr)"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vm.name}"
}

# Create subnet
resource "azurerm_subnet" "vm" {
    name                 = "subnet-$(var.suffix)"
    resource_group_name  = "${azurerm_resource_group.vm.name}"
    virtual_network_name = "${azurerm_virtual_network.vm.name}"
    address_prefix       = "$(var.snet_addr)"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm" {
    name                = "nsg-$(var.suffix)"
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

resource "azurerm_virtual_machine" "vm-linux-with-datadisk" {
  count                         = "${var.nb_instances}"
  name                          = "${var.vm_hostname}${count.index}"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.vm.name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.vm.*.id, count.index)}"]
  delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer     = "${var.vm_os_offer}"
    sku       = "${var.vm_os_sku}"
    version   = "${var.vm_os_version}"
  }

  storage_os_disk {
    name              = "osdisk-${var.vm_hostname}-${count.index}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "${var.storage_account_type}"
  }

  storage_data_disk {
    name              = "datadisk-${var.vm_hostname}-${count.index}"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "${var.vm_hostname}${count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }
}

resource "azurerm_public_ip" "vm" {
  count                        = "${var.nb_public_ip}"
  name                         = "${var.vm_hostname}-${count.index}-publicIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.vm.name}"
  public_ip_address_allocation = "${var.public_ip_address_allocation}"
}


resource "azurerm_network_interface" "vm" {
  count                         = "${var.nb_instances}"
  name                          = "nic-${var.vm_hostname}-${count.index}"
  location                      = "${azurerm_resource_group.vm.location}"
  resource_group_name           = "${azurerm_resource_group.vm.name}"
  network_security_group_id     = "${azurerm_network_security_group.vm.id}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${azurerm_subnet.vm.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${length(azurerm_public_ip.vm.*.id) > 0 ? element(concat(azurerm_public_ip.vm.*.id, list("")), count.index) : ""}"
  }

  tags = "${var.tags}"
}
