resource "azurerm_managed_disk" "shared-data-disk" {
    name = local.shared_disk_name # "shared-data-disk" #
    resource_group_name = "SharedResources" # "NetworkWatcherRG" # 
    location = var.location
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb = 32

    lifecycle {
       prevent_destroy = true
    }    
}
