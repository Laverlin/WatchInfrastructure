#!/bin/bash

cd helm
helm upgrade watch-micro watch-micro -n watch-backend --install --values secret.dev-values.yaml --kubeconfig ~/remote-kube/xps-gold.ivan-b.com/config
cd ..