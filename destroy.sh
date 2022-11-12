#!/bin/bash

cd terraform
terraform state rm azurerm_managed_disk.shared-data-disk
terraform destroy --auto-approve
cd ..