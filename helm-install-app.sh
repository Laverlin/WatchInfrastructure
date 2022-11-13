#!/bin/bash

cd helm
helm upgrade watch-micro watch-micro -n watch-backend --install --values prod-values.secret.yaml --kubeconfig ~/remote-kube/ivan-b.com/config
cd ..


# helm upgrade otel-collector otel-collector -n monitoring --install --values generated-values.yaml --kubeconfig ~/remote-kube/ivan-b.com/config