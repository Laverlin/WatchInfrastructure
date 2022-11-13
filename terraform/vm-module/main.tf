resource "azurerm_linux_virtual_machine" "vm" {
    # for_each = {
    #   "master" = {size = "Standard_B2s", nic-id = azurerm_network_interface.nic[0].id}
    #   "worker" = {size = "Standard_B1ms", nic-id = azurerm_network_interface.nic[1].id} 
    # }
    name                  = "${var.vm_name}"
    location              = var.location
    resource_group_name   = var.rg_name
    network_interface_ids = [var.nic.id]
    size                  = var.vm_size
    availability_set_id   = var.av_id

    os_disk {
        name              = "${var.vm_name}-disk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 30
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy" # "0001-com-ubuntu-server-focal" # 
        sku       = "22_04-lts-gen2" # "20_04-lts-gen2" # 
        version   = "latest"
    }

    computer_name  = "${var.vm_name}"
    admin_username = var.admin_username
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.admin_username
        public_key     = file(var.admin_public_key_path)
    }

}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-attachment" {
  managed_disk_id    = var.shared_disk_id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "10"
  caching            = "None"
  count              = azurerm_linux_virtual_machine.vm.name == "barolo" ? 1: 0
}


resource "azurerm_lb_nat_rule" "ssh_rule" {
  resource_group_name            = var.rg_name
  loadbalancer_id                = var.load_balancer.id
  name                           = "SSH-${var.vm_ssh_port}"
  protocol                       = "Tcp"
  frontend_port                  = var.vm_ssh_port
  backend_port                   = 22
  frontend_ip_configuration_name = var.load_balancer.frontend_ip_configuration[0].name
  depends_on = [var.load_balancer]
}

resource "azurerm_network_interface_nat_rule_association" "nic_nat" {
  network_interface_id  = var.nic.id
  ip_configuration_name = var.nic.ip_configuration[0].name 
  nat_rule_id           = azurerm_lb_nat_rule.ssh_rule.id
}