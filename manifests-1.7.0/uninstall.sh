#!/bin/bash

# Cert-Manager
kubectl delete -k common/cert-manager/cert-manager/base
kubectl delete -k common/cert-manager/kubeflow-issuer/base
# Istio
kubectl delete -k common/istio-1-16/istio-crds/base
kubectl delete -k common/istio-1-16/istio-namespace/base
kubectl delete -k common/istio-1-16/istio-install/base
# OIDC Authservice
kubectl delete -k common/oidc-authservice/base
# Dex
kubectl delete -k common/dex/overlays/istio
# KNative
kubectl delete -k common/knative/knative-serving/overlays/gateways
kubectl delete -k common/knative/knative-eventing/base
kubectl delete -k common/istio-1-16/cluster-local-gateway/base
# Kubeflow namespace
kubectl delete -k common/kubeflow-namespace/base
# Kubeflow Roles
kubectl delete -k common/kubeflow-roles/base
# Kubeflow Istio Resources
kubectl delete -k common/istio-1-16/kubeflow-istio-resources/base


# Kubeflow Pipelines
kubectl delete -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user
# Katib
kubectl delete -k apps/katib/upstream/installs/katib-with-kubeflow
# Central Dashboard
kubectl delete -k apps/centraldashboard/upstream/overlays/kserve
# Admission Webhook
kubectl delete -k apps/admission-webhook/upstream/overlays/cert-manager
# Jupyter Web App
kubectl delete -k apps/jupyter/jupyter-web-app/upstream/overlays/istio
# Notebook Controller
kubectl delete -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
# Profiles + KFAM
kubectl delete -k apps/profiles/upstream/overlays/kubeflow
# Volumes Web App
kubectl delete -k apps/volumes-web-app/upstream/overlays/istio
# Tensorboards Controller
kubectl delete -k  apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow
# Tensorboard Web App
kubectl delete -k  apps/tensorboard/tensorboards-web-app/upstream/overlays/istio
# Training Operator
kubectl delete -k apps/training-operator/upstream/overlays/kubeflow
# User namespace
kubectl delete -k common/user-namespace/base

# KServe
kubectl delete -k contrib/kserve/kserve
kubectl delete -k contrib/kserve/models-web-app/overlays/kubeflow
