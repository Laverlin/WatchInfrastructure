#!/bin/bash

echo "Deploy k8s cluster on azure"
cd terraform
terraform apply --auto-approve

read -t 60 -n 1 -p "Now we'll apply ansible scripts. Continue (Y/n)?" answer
echo 

if [ "${answer}" == "n" ]
then
  exit 1
fi

cd ../ansible
ansible-playbook -i inventory.yaml setup-k8s.yaml