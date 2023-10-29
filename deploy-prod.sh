#!/bin/bash

sed -i -e '/deploy_env/s/dev/prod/g' terraform/secret.auto.tfvars
sed -i -e '/deploy_env/s/stage/prod/g' terraform/secret.auto.tfvars

. terraform/secret.auto.tfvars

echo "Deploy PROD k8s cluster on azure"
cd terraform
terraform workspace select prod
terraform import azurerm_managed_disk.shared-data-disk $AZURE_DISK_PROD
terraform apply --auto-approve -compact-warnings

read -t 60 -n 1 -p "Now we'll apply ansible scripts. Continue (Y/n)?" answer
echo 

if [ "${answer}" == "n" ]
then
  exit 1
fi

cd ../ansible
ansible-playbook -i inventory-prod.yaml setup-k8s.yaml
cd ..