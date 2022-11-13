#!/bin/bash

cd terraform
terraform workspace select stage
terraform state rm azurerm_managed_disk.shared-data-disk
terraform destroy --auto-approve
cd ..