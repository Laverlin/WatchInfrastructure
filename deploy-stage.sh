#!/bin/bash

sed -i -e '/deploy_env/s/dev/stage/g' terraform/secret.auto.tfvars
sed -i -e '/deploy_env/s/prod/stage/g' terraform/secret.auto.tfvars

. terraform/secret.auto.tfvars

echo "Deploy k8s cluster on azure"
cd terraform
terraform import azurerm_managed_disk.shared-data-disk $AZURE_DISK_STAGE
terraform apply --auto-approve -compact-warnings

read -t 60 -n 1 -p "Now we'll apply ansible scripts. Continue (Y/n)?" answer
echo 

if [ "${answer}" == "n" ]
then
  exit 1
fi

cd ../ansible
ansible-playbook -i inventory-current.yaml setup-k8s.yaml
cd ..