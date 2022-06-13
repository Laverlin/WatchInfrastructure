#############################################################################
# VARIABLES
#############################################################################

variable "azure_subscription_id" {}
variable "azure_tenant_id" {}
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "admin_username" {}
variable "admin_public_key_path" {}
variable "admin_private_key_path" {}

variable "azure_storage_account" {}
variable "azure_sas_token" {}
variable "azure_container_name" {}
variable "azure_storage_key" {}

variable "namecom_user" {}
variable "namecom_token" {}
variable "domain_name" {}

variable "env_postgress_user" {}
variable "env_postgress_password" {}
variable "vpn_pre_shared_key" {}
variable "vpn_username" {}
variable "vpn_password" {}

variable "ws_location_key" {}
variable "ws_dark_sky_key" {}
variable "ws_open_weather_key" {}
variable "ws_currency_converter_key" {}
variable "ws_auth_token" {}
variable "telegram_yas_bot_key" {}
variable "telegram_chat_id" {}
variable "app_insights_key" {}

variable "node_count" {
  type = number
  default = 2
}

variable "project_name" { 
  type = string 
  default = "montalcino"
}

variable "location" {
  type = string
  default = "West Europe"
}

variable "vm_size" {
  type = string
  default = "Standard_B2s"
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id = var.azure_tenant_id
  client_id = var.azure_client_id
  client_secret = var.azure_client_secret
}

#############################################################################
# RESOURCES
#############################################################################

// Resource Group
//
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags = {
      project = var.project_name
  }  
}

// Virtual Network
//
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.project_name}-vnet"
    address_space       = ["10.12.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        project = var.project_name
    }
}

// Subnet
//
resource "azurerm_subnet" "subnet" {
    name                 = "${var.project_name}-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["10.12.0.0/24"]
}

// Public IP
//
resource "azurerm_public_ip" "public_ip" {
    name                         = "${var.project_name}-ip"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"

    tags = {
        project = var.project_name
    }
}

// Network Interface Card.
//
resource "azurerm_network_interface" "nic" {
    count                       = var.node_count
    name                        = "${var.project_name}-${format("%02d", count.index)}-nic"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "nic-config-${var.project_name}"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        project = var.project_name
    }
}

resource "azurerm_lb" "lb" {
  name                = "${var.project_name}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "addr_pool" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "accpool"
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_pool" {
  count = var.node_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name 
  backend_address_pool_id = azurerm_lb_backend_address_pool.addr_pool.id
}

// Connect the security group to the subnet
//
resource "azurerm_subnet_network_security_group_association" "nsg_sub_ass" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = var.location
   resource_group_name          = azurerm_resource_group.rg.name
   managed                      = true
 }

// Create virtual machines
//
resource "azurerm_linux_virtual_machine" "master-vm" {
    name                  = "${var.project_name}-master-vm"
    location              = var.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic[0].id]
    size                  = var.vm_size
    availability_set_id   = azurerm_availability_set.avset.id

    os_disk {
        name              = "${var.project_name}-master-disk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 30
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
    }

    computer_name  = "${var.project_name}-master-vm"
    admin_username = var.admin_username
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.admin_username
        public_key     = file(var.admin_public_key_path)
    }

    tags = {
        project = var.project_name
    }
}

// VM 2
//
resource "azurerm_linux_virtual_machine" "worker-vm" {
    name                  = "${var.project_name}-worker-vm"
    location              = var.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic[1].id]
    size                  = "Standard_B1ms"
    availability_set_id   = azurerm_availability_set.avset.id

    os_disk {
        name              = "${var.project_name}-worker-disk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 30
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
    }

    computer_name  = "${var.project_name}-worker-vm"
    admin_username = var.admin_username
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.admin_username
        public_key     = file(var.admin_public_key_path)
    }

    tags = {
        project = var.project_name
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-master-attachment" {
  managed_disk_id    = azurerm_managed_disk.shared-data-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.master-vm.id
  lun                = "10"
  caching            = "None"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-worker-attachment" {
  managed_disk_id    = azurerm_managed_disk.shared-data-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.worker-vm.id
  lun                = "10"
  caching            = "None"
}

/*

resource "null_resource" "vm-script-deploy" {
  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.public_ip.ip_address
    user        = var.admin_username
    private_key = file(var.admin_private_key_path)
    port        = 50221

  }

  provisioner "file" {
    source      = "docker-hub"
    destination = "/home/${var.admin_username}/"
  }

  provisioner "file" {
    content = <<EOF
VPN_IPSEC_PSK="${var.vpn_pre_shared_key}"
VPN_USER="${var.vpn_username}"
VPN_PASSWORD="${var.vpn_password}"
NAMECOM_USER=${var.namecom_user}
NAMECOM_TOKEN=${var.namecom_token}
DOMAIN_NAME=${var.domain_name}
PG_USER=${var.env_postgress_user}
PG_PASS=${var.env_postgress_password}
AZ_STORAGE_ACCOUNT=${var.azure_storage_account}
AZ_SAS_TOKEN=${var.azure_sas_token}
AZ_CONTAINER_NAME=${var.azure_container_name}
AZ_STORAGE_KEY=${var.azure_storage_key}
WS_LOCATION_KEY=${var.ws_location_key}
WS_DARK_SKY_KEY=${var.ws_dark_sky_key}
WS_OPEN_WEATHER_KEY=${var.ws_open_weather_key}
WS_CURRENCY_CONVERTER_KEY=${var.ws_currency_converter_key}
WS_AUTH_TOKEN=${var.ws_auth_token}
TELEGRAM_YAS_BOT_KEY=${var.telegram_yas_bot_key}
TELEGRAM_CHAT_ID=${var.telegram_chat_id}
APP_INSIGHTS_KEY=${var.app_insights_key}
ADMIN_USERNAME=${var.admin_username}
VM_PRIVATE_IP=${azurerm_network_interface.nic.private_ip_address}
EOF
    destination = "/home/${var.admin_username}/docker-hub/.env"
  }


provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.admin_username}/docker-hub/deploy-script.sh",
      "sudo /home/${var.admin_username}/docker-hub/deploy-script.sh",
    ]
  }    
}
*/

#############################################################################
# OUTPUTS
#############################################################################

output "resource_group"{
  value = azurerm_resource_group.rg
}

output "domain_name" {
  value = var.domain_name 
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.nic.*.private_ip_address
}
