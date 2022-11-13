#############################################################################
# VARIABLES
#############################################################################

variable "deploy_env" {}

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
variable "namecom_domain" {}

variable "prod_namecom_fqn" {}
variable "prod_namecom_host" {}
variable "prod_namecom_entry_id" {}

variable "stage_namecom_fqn" {}
variable "stage_namecom_host" {}
variable "stage_namecom_entry_id" {}

variable "project_name" {}

locals {
  project = "${var.project_name}-${var.deploy_env}"
  resourcegroup = "${local.project}-rg" 

  namecom_fqn = var.deploy_env == "prod" ? var.prod_namecom_fqn : var.stage_namecom_fqn
  namecom_host = var.deploy_env == "prod" ? var.prod_namecom_host : var.stage_namecom_host
  namecom_entry_id = var.deploy_env == "prod" ? var.prod_namecom_entry_id : var.stage_namecom_entry_id
  shared_disk_name = "nb-${var.deploy_env}-disk"
}

variable "vpn_pre_shared_key" {}
variable "vpn_username" {}
variable "vpn_password" {}

variable "ws_location_key" {}
variable "ws_dark_sky_key" {}
variable "ws_open_weather_key" {}
variable "ws_currency_converter_key" {}
variable "ws_twelve_data_key" {}
variable "ws_auth_token" {}

variable "telegram_chat_id" {}
variable "app_insights_key" {}

variable "location" {}

variable "node_count" {
  type = number
  default = 3
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
  name     = "${local.resourcegroup}"
  location = var.location
  tags = {
      project = local.project
  }  
}

// Virtual Network
//
resource "azurerm_virtual_network" "vnet" {
    name                = "${local.project}-vnet"
    address_space       = ["10.12.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        project = local.project
    }
}

// Subnet
//
resource "azurerm_subnet" "subnet" {
    name                 = "${local.project}-subnet"
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
    name                         = "${local.project}-ip"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"

    tags = {
        project = local.project
    }
}


// Network Interface Cards
//
resource "azurerm_network_interface" "nic" {
    count                       = var.node_count
    name                        = "${local.project}-${format("%02d", count.index)}-nic"
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
        project = local.project
    }
}

// Load Balancer
//
resource "azurerm_lb" "lb" {
  name                = "${local.project}-lb"
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
    "barolo"      = {size = "Standard_B1ms", nic = azurerm_network_interface.nic[0], port  = 50022}
    "barbaresco"  = {size = "Standard_B2s", nic = azurerm_network_interface.nic[1], port  = 50122}
    "sfursat"     = {size = "Standard_B2s", nic = azurerm_network_interface.nic[2], port  = 50222}
  }
  vm_name                 = "${each.key}"
  rg_name                 = azurerm_resource_group.rg.name
  location                = var.location
  nic                     = each.value.nic
  admin_public_key_path   = var.admin_public_key_path
  admin_username          = var.admin_username
  vm_size                 = each.value.size
  shared_disk_id          = azurerm_managed_disk.shared-data-disk.id
  av_id                   = azurerm_availability_set.avset.id
  vm_ssh_port             = each.value.port
  load_balancer           = azurerm_lb.lb
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
    port        = 50022

  }

  provisioner "remote-exec" {
    inline = [
      "curl -u '${var.namecom_user}:${var.namecom_token}' 'https://api.name.com/v4/domains/${var.namecom_domain}/records/${local.namecom_entry_id}' -X PUT -H 'Content-Type: application/json' --data '{\"host\":\"${local.namecom_host}\",\"type\":\"A\",\"answer\":\"${azurerm_public_ip.public_ip.ip_address}\",\"ttl\":300}'"
    ]
  }
  
}

resource "local_file" "inventory" {
    content = <<EOF
all:
  hosts:
    barolo:
      ansible_port: 50022
    barbaresco:
      ansible_port: 50122
    sfursat:
      ansible_port: 50222
  vars:
    ansible_host: ${local.namecom_fqn}
    ansible_user: ${var.admin_username}
    ansible_ssh_private_key_file: ${var.admin_private_key_path}
    ansible_ssh_common_args: -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    public_ip: ${azurerm_public_ip.public_ip.ip_address}
EOF
  filename = "../ansible/inventory-${var.deploy_env}.yaml"
}

#############################################################################
# OUTPUTS
#############################################################################

output "resource_group"{
  value = azurerm_resource_group.rg
}

output "domain_name" {
  value = local.namecom_fqn 
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.nic.*.private_ip_address
}
