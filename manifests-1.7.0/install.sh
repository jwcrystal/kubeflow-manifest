#!/bin/bash

# Cert-Manager
kubectl apply -k common/cert-manager/cert-manager/base
kubectl apply -k common/cert-manager/kubeflow-issuer/base
# Istio
kubectl apply -k common/istio-1-16/istio-crds/base
kubectl apply -k common/istio-1-16/istio-namespace/base
kubectl apply -k common/istio-1-16/istio-install/base
# OIDC Authservice
kubectl apply -k common/oidc-authservice/base
# Dex
kubectl apply -k common/dex/overlays/istio
# KNative
kubectl apply -k common/knative/knative-serving/overlays/gateways
kubectl apply -k common/knative/knative-eventing/base
kubectl apply -k common/istio-1-16/cluster-local-gateway/base
# Kubeflow namespace
kubectl apply -k common/kubeflow-namespace/base
# Kubeflow Roles
kubectl apply -k common/kubeflow-roles/base
# Kubeflow Istio Resources
kubectl apply -k common/istio-1-16/kubeflow-istio-resources/base


# Kubeflow Pipelines
kubectl apply -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user
# Katib
kubectl apply -k apps/katib/upstream/installs/katib-with-kubeflow
# Central Dashboard
kubectl apply -k apps/centraldashboard/upstream/overlays/kserve
# Admission Webhook
kubectl apply -k apps/admission-webhook/upstream/overlays/cert-manager
# Jupyter Web App
kubectl apply -k apps/jupyter/jupyter-web-app/upstream/overlays/istio
# Notebook Controller
kubectl apply -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
# Profiles + KFAM
kubectl apply -k apps/profiles/upstream/overlays/kubeflow
# Volumes Web App
kubectl apply -k apps/volumes-web-app/upstream/overlays/istio
# Tensorboards Controller
kubectl apply -k  apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow
# Tensorboard Web App
kubectl apply -k  apps/tensorboard/tensorboards-web-app/upstream/overlays/istio
# Training Operator
kubectl apply -k apps/training-operator/upstream/overlays/kubeflow
# User namespace
kubectl apply -k common/user-namespace/base

# KServe
kubectl apply -k contrib/kserve/kserve
kubectl apply -k contrib/kserve/models-web-app/overlays/kubeflow
