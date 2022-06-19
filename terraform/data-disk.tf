# resource "azurerm_managed_disk" "shared-data-disk" {
#     name = "shared-data-disk"
#     resource_group_name = "NetworkWatcherRG"
#     location = var.location
#     storage_account_type = "StandardSSD_LRS"
#     create_option        = "Empty"
#     disk_size_gb = 64

#     lifecycle {
#        prevent_destroy = true
#     }    
# }