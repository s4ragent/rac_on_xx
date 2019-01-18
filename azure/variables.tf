variable "suffix" {
  default     = "raconxx"
}

variable "resource_group_name" {
  default     = "rg_raconxx"
}

variable "vnet_addr" {
  default     = "10.153.0.0/16"
}

variable "snet_addr" {
  default     = "10.153.1.0/24"
}

variable "location" {
  default     = "westus2"
#  default     = "japanwest"
}

variable "public_key" {
  default     = ""
}

variable "admin_username" {
  default     = ""  
}

variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  default     = "Standard_LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_A2m_v2"
}

variable "nb_instances" {
  description = "Specify the number of vm instances"
}

variable "vm_hostname" {
  description = "local name of the VM"
  default     = "node"
}


variable "vm_os_publisher" {
  description = "The name of the publisher of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "Oracle"
}

variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "Oracle-Linux"
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "7.4"
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "latest"
}

variable "tags" {
  type        = "map"
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "public_ip_address_allocation" {
  description = "Defines how an IP address is assigned. Options are Static or Dynamic."
  default     = "dynamic"
}

variable "nb_public_ip" {
  description = "Number of public IPs to assign corresponding to one IP per vm. Set to 0 to not assign any public IP addresses."
  default     = "1"
}

variable "delete_os_disk_on_termination" {
  description = "Delete datadisk when machine is terminated"
  default     = "true"
}

variable "data_sa_type" {
  description = "Data Disk Storage Account type"
  default     = "Standard_LRS"
}

variable "data_disk_size_gb" {
  description = "Storage data disk size size"
  default     = "100"
}
