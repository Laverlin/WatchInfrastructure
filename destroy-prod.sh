#!/bin/bash

echo Destroy PROD cluster

cd terraform
terraform workspace select prod
terraform state rm azurerm_managed_disk.shared-data-disk
terraform destroy --auto-approve
cd ..