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
variable "namecom_fqn" {}
variable "namecom_host" {}
variable "namecom_domain" {}
variable "namecom_entry_id" {}
variable "acme_server" {}

variable "env_postgress_user" {}
variable "env_postgress_password" {}

variable "gf_keycloak_client_secret" {}
variable "kd_keycloak_client_secret" {}

variable "mssql_user" {}
variable "mssql_password" {}

variable "vpn_pre_shared_key" {}
variable "vpn_username" {}
variable "vpn_password" {}

variable "ws_location_key" {}
variable "ws_dark_sky_key" {}
variable "ws_open_weather_key" {}
variable "ws_currency_converter_key" {}
variable "ws_twelve_data_key" {}
variable "ws_auth_token" {}
variable "telegram_yas_bot_key" {}
variable "telegram_chat_id" {}
variable "app_insights_key" {}

variable "project_name" {}
variable azure_resourcegroup {}
variable azure_vnet {}
variable azure_subnet {}
variable azure_nsg {}
variable azure_disk {}
variable azure_storage_data {}

variable "location" {}

variable "node_count" {
  type = number
  default = 2
}

# variable "vm_size" {
#   type = string
#   default = "Standard_B2s"
# }

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
  name     = "${var.azure_resourcegroup}"
  location = var.location
  tags = {
      project = var.project_name
  }  
}

// Virtual Network
//
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.azure_vnet}"
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
    name                 = "${var.azure_subnet}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["10.12.0.0/24"]
}

// Connect the security group to the subnet
//
resource "azurerm_subnet_network_security_group_association" "nsg_sub_ass" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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


// Network Interface Cards
//
resource "azurerm_network_interface" "nic" {
    count                       = var.node_count
    name                        = "${var.project_name}-${format("%02d", count.index)}-nic"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    enable_ip_forwarding        = true

    ip_configuration {
        name                          = "ip-config-main"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        primary                       = true
    }

    # dynamic "ip_configuration" {
    #   for_each=range(100)
    #   content {
    #     name                          = "ip-config-${ip_configuration.value}"
    #     subnet_id                     = azurerm_subnet.subnet.id
    #     private_ip_address_allocation = "Dynamic"
    #   }
    # }

    tags = {
        project = var.project_name
    }
}

// Load Balancer
//
resource "azurerm_lb" "lb" {
  name                = "${var.project_name}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

}

// Create backend address pool for the LoadBalancer
//
resource "azurerm_lb_backend_address_pool" "addr_pool" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "accpool"
}

// Attach all interface card to the lb via backend address pool
//
resource "azurerm_network_interface_backend_address_pool_association" "nic_pool" {
  count = var.node_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name 
  backend_address_pool_id = azurerm_lb_backend_address_pool.addr_pool.id
}

// Create availability set as basic Load Balancer can work only with VMs in the same availability set
//
resource "azurerm_availability_set" "avset" {
   name                         = "av-set"
   location                     = var.location
   resource_group_name          = azurerm_resource_group.rg.name
   managed                      = true
 }

############################################
#  Virtual machines
############################################

module "vm-module" {
  source           = "./vm-module"
  for_each = {
    "barolo" = {size = "Standard_B2s", nic-id = azurerm_network_interface.nic[0].id}
    "vouvrey" = {size = "Standard_B2s", nic-id = azurerm_network_interface.nic[1].id} 
  }
  vm_name          = "${each.key}"
  rg_name          = azurerm_resource_group.rg.name
  location         = var.location
  nic_id           = each.value.nic-id
  admin_public_key_path        = var.admin_public_key_path
  admin_username    = var.admin_username
  vm_size           = each.value.size
  #shared_disk_id    = azurerm_managed_disk.shared-data-disk.id
  av_id             = azurerm_availability_set.avset.id
}


resource "null_resource" "vm-script-deploy" {
  depends_on = [
    module.vm-module
  ]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.public_ip.ip_address
    user        = var.admin_username
    private_key = file(var.admin_private_key_path)
    port        = 50221

  }

  provisioner "remote-exec" {
    inline = [
      "curl -u '${var.namecom_user}:${var.namecom_token}' 'https://api.name.com/v4/domains/${var.namecom_domain}/records/${var.namecom_entry_id}' -X PUT -H 'Content-Type: application/json' --data '{\"host\":\"${var.namecom_host}\",\"type\":\"A\",\"answer\":\"${azurerm_public_ip.public_ip.ip_address}\",\"ttl\":300}'"
    ]
  }

  provisioner "file" {
    content = <<EOF
VPN_IPSEC_PSK="${var.vpn_pre_shared_key}"
VPN_USER="${var.vpn_username}"
VPN_PASSWORD="${var.vpn_password}"
NAMECOM_USER=${var.namecom_user}
NAMECOM_TOKEN=${var.namecom_token}
DOMAIN_NAME=${var.namecom_fqn}
PG_USER=${var.env_postgress_user}
PG_PASS=${var.env_postgress_password}
MSSQL_USER=${var.mssql_user}
MSSQL_PASSWORD=${var.mssql_password}
AZ_STORAGE_ACCOUNT=${var.azure_storage_account}
AZ_SAS_TOKEN=${var.azure_sas_token}
AZ_CONTAINER_NAME=${var.azure_container_name}
AZ_STORAGE_KEY=${var.azure_storage_key}
WS_LOCATION_KEY=${var.ws_location_key}
WS_DARK_SKY_KEY=${var.ws_dark_sky_key}
WS_OPEN_WEATHER_KEY=${var.ws_open_weather_key}
WS_CURRENCY_CONVERTER_KEY=${var.ws_currency_converter_key}
WS_TWELVE_DATA_KEY=${var.ws_twelve_data_key}
WS_AUTH_TOKEN=${var.ws_auth_token}
TELEGRAM_YAS_BOT_KEY=${var.telegram_yas_bot_key}
TELEGRAM_CHAT_ID=${var.telegram_chat_id}
APP_INSIGHTS_KEY=${var.app_insights_key}
ADMIN_USERNAME=${var.admin_username}
GF_KEYCLOAK_CLIENT_SECRET=${var.gf_keycloak_client_secret}
VM_PRIVATE_IP=${azurerm_network_interface.nic[0].private_ip_address}
EOF
    destination = "/home/${var.admin_username}/.env"
  }
  
}

resource "local_file" "inventory" {
    content = <<EOF
all:
  hosts:
    master:
      ansible_port: 50221
    worker:
      ansible_port: 50222
  vars:
    ansible_host: ${var.namecom_fqn}
    ansible_user: ${var.admin_username}
    ansible_ssh_private_key_file: ${var.admin_private_key_path}
    ansible_ssh_common_args: -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    public_ip: ${azurerm_public_ip.public_ip.ip_address}
EOF
  filename = "../ansible/inventory-current.yaml"
}

#############################################################################
# OUTPUTS
#############################################################################

output "resource_group"{
  value = azurerm_resource_group.rg
}

output "domain_name" {
  value = var.namecom_fqn 
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.nic.*.private_ip_address
}
