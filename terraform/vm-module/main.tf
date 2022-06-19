resource "azurerm_linux_virtual_machine" "vm" {
    # for_each = {
    #   "master" = {size = "Standard_B2s", nic-id = azurerm_network_interface.nic[0].id}
    #   "worker" = {size = "Standard_B1ms", nic-id = azurerm_network_interface.nic[1].id} 
    # }
    name                  = "${var.vm_name}"
    location              = var.location
    resource_group_name   = var.rg_name
    network_interface_ids = [var.nic_id]
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
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
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

# resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-attachment-m" {
#   managed_disk_id    = var.shared_disk_id
#   virtual_machine_id = azurerm_linux_virtual_machine.vm.id
#   lun                = "10"
#   caching            = "None"
# }