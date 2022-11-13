#!/bin/bash

sed -i -e '/deploy_env/s/prod/dev/g' terraform/secret.auto.tfvars
sed -i -e '/deploy_env/s/stage/dev/g' terraform/secret.auto.tfvars


cd ansible
ansible-playbook -i inventory-local.yaml setup-k8s.yaml
cd ..