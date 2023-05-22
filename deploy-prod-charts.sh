#!/bin/bash

sed -i -e '/deploy_env/s/dev/prod/g' terraform/secret.auto.tfvars
sed -i -e '/deploy_env/s/stage/prod/g' terraform/secret.auto.tfvars


cd ansible
ansible-playbook -i inventory-prod.yaml update-helms.yaml
cd ..