# Kubeflow in Local Environment
> modified from Kubeflow/manifest

- [Kubeflow in Local Environment](#kubeflow-in-local-environment)
  - [Prerequisite](#prerequisite)
  - [Install pre-config](#install-pre-config)
    - [install local stoage class](#install-local-stoage-class)
    - [Install pre-PVCs](#install-pre-pvcs)
  - [Install full of kubelflow](#install-full-of-kubelflow)
    - [with Single command](#with-single-command)
    - [with individual components](#with-individual-components)
      - [cert-manager](#cert-manager)
      - [Istio](#istio)
      - [Dex](#dex)
      - [OIDC AuthService](#oidc-authservice)
      - [Knative](#knative)
      - [Kubeflow Namespace](#kubeflow-namespace)
      - [Kubeflow Roles](#kubeflow-roles)
      - [Kubeflow Istio Resources](#kubeflow-istio-resources)
      - [Kubeflow Pipelines](#kubeflow-pipelines)
      - [KServe](#kserve)
      - [Katib](#katib)
      - [Central Dashboard](#central-dashboard)
      - [Admission Webhook](#admission-webhook)
      - [Notebooks](#notebooks)
      - [Profiles + KFAM](#profiles-kfam)
      - [Volumes Web App](#volumes-web-app)
      - [Tensorboard](#tensorboard)
      - [Training Operator](#training-operator)
      - [User Namespace](#user-namespace)
    - [Connect to your Kubeflow Cluster](#connect-to-your-kubeflow-cluster)
    - [Change default user password](#change-default-user-password)
  - [Uninstall](#uninstall)
  - [Note](#note)
  - [Reference](#reference)

## Prerequisite

- Kubernetes (up to 1.27) with a default StorageClass
- kubectl

NOTE
> `kubectl apply` commands may fail on the first try. This is inherent in how Kubernetes and kubectl work (e.g., CR must be created after CRD becomes ready). The solution is to simply re-run the command until it succeeds. For the single-line command, we have included a bash one-liner to retry the command.

## Install pre-config

### install local stoage class

- install dynamically provisioning persistent local storage
```sh
kubectl apply -f local-path-storage.yaml
```

- set default storage class if the command above did not work after installed
```sh
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Install pre-PVCs

because manifests will be installed and worked if pv is needed when the pvc pre-existed. 

```sh
kubectl apply -f authservice-pvc.yaml
kubectl apply -f katib-mysql.yaml
kubectl apply -f minio-pvc.yaml
kubectl apply -f mysql-pv-claim.yaml
```

## Install full of kubelflow

### with Single command

In manifest folder
```sh
souce ./install.sh
```

### with individual components

install each Kubeflow official component (under apps) and each common service (under common) separately, using `kubectl`.

The purpose of this section is to:

* Provide a description of each component and insight on how it gets installed.
* Enable the user or distribution owner to pick and choose only the components they need.

**Troubleshooting note**

We've seen errors like the following when applying the kustomizations of different components:

```sh
error: resource mapping not found for name: "<RESOURCE_NAME>" namespace: "<SOME_NAMESPACE>" from "STDIN": no matches for kind "<CRD_NAME>" in version "<CRD_FULL_NAME>"
ensure CRDs are installed first
```

This is because a kustomization applies both a CRD and a CR very quickly, and the CRD hasn't become `Established` yet. You can learn more about this in [kubernetes/kubectl#1117](https://github.com/kubernetes/kubectl/issues/1117) and [helm/helm#4925](https://github.com/helm/helm/issues/4925).

#### cert-manager

cert-manager is used by many Kubeflow components to provide certificates for
admission webhooks.

Install cert-manager:

```sh
kubectl apply -k common/cert-manager/cert-manager/base
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl apply -k common/cert-manager/kubeflow-issuer/base
```

In case you get this error:
```
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": dial tcp 10.96.202.64:443: connect: connection refused
```
This is because the webhook is not yet ready to receive request. Wait a couple seconds and retry applying the manfiests.

For more troubleshooting info also check out https://cert-manager.io/docs/troubleshooting/webhook/

#### Istio

Istio is used by many Kubeflow components to secure their traffic, enforce
network authorization and implement routing policies.

Install Istio:

```sh
kubectl apply -k common/istio-1-17/istio-crds/base
kubectl apply -k common/istio-1-17/istio-namespace/base
kubectl apply -k common/istio-1-17/istio-install/base
```

#### Dex

Dex is an OpenID Connect Identity (OIDC) with multiple authentication backends. In this default installation, it includes a static user with email `user@example.com`. By default, the user's password is `12341234`. For any production Kubeflow deployment, you should change the default password by following [the relevant section](#change-default-user-password).

Install Dex:

```sh
kubectl apply -k common/dex/overlays/istio
```

#### OIDC AuthService

The OIDC AuthService extends your Istio Ingress-Gateway capabilities, to be able to function as an OIDC client:

```sh
kubectl apply -k common/oidc-authservice/base
```

#### Knative

Knative is used by the KServe official Kubeflow component.

Install Knative Serving:

```sh
kubectl apply -k common/knative/knative-serving/overlays/gateways
kubectl apply -k common/istio-1-17/cluster-local-gateway/base
```

Optionally, you can install Knative Eventing which can be used for inference request logging:

```sh
kubectl apply -k common/knative/knative-eventing/base
```

#### Kubeflow Namespace

Create the namespace where the Kubeflow components will live in. This namespace
is named `kubeflow`.

Install kubeflow namespace:

```sh
kubectl apply -k common/kubeflow-namespace/base
```

#### Kubeflow Roles

Create the Kubeflow ClusterRoles, `kubeflow-view`, `kubeflow-edit` and
`kubeflow-admin`. Kubeflow components aggregate permissions to these
ClusterRoles.

Install kubeflow roles:

```sh
kubectl apply -k common/kubeflow-roles/base
```

#### Kubeflow Istio Resources

Create the Istio resources needed by Kubeflow. This kustomization currently
creates an Istio Gateway named `kubeflow-gateway`, in namespace `kubeflow`.
If you want to install with your own Istio, then you need this kustomization as
well.

Install istio resources:

```sh
kubectl apply -k common/istio-1-17/kubeflow-istio-resources/base
```

#### Kubeflow Pipelines

Install the [Multi-User Kubeflow Pipelines](https://www.kubeflow.org/docs/components/pipelines/multi-user/) official Kubeflow component:

```sh
kubectl apply -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user
```
This installs argo with the safe-to use runasnonroot emissary executor.  Please note that the installer is still responsible to analyze the security issues that arise when containers are run with root access and to decide if the kubeflow pipeline main containers are run as runasnonroot. It is strongly recommended that the pipelines main containers are installed and run as runasnonroot and without any special capabilities to mitigate security risks.

Refer to [argo workflow executor documentation](https://argoproj.github.io/argo-workflows/workflow-executors) for further reasoning.

**Multi-User Kubeflow Pipelines dependencies**

* Istio + Kubeflow Istio Resources
* Kubeflow Roles
* OIDC Auth Service (or cloud provider specific auth service)
* Profiles + KFAM

**Alternative: Kubeflow Pipelines Standalone**

You can install [Kubeflow Pipelines Standalone](https://www.kubeflow.org/docs/components/pipelines/installation/standalone-deployment/) which

* does not support multi user separation
* has no dependencies on the other services mentioned here

You can learn more about their differences in [Installation Options for Kubeflow Pipelines
](https://www.kubeflow.org/docs/components/pipelines/installation/overview/).

Besides installation instructions in Kubeflow Pipelines Standalone documentation, you need to apply two virtual services to expose [Kubeflow Pipelines UI](https://github.com/kubeflow/pipelines/blob/1.7.0/manifests/kustomize/base/installs/multi-user/virtual-service.yaml) and [Metadata API](https://github.com/kubeflow/pipelines/blob/1.7.0/manifests/kustomize/base/metadata/options/istio/virtual-service.yaml) in kubeflow-gateway.

#### KServe

Install the KServe component:

```sh
kubectl apply -k contrib/kserve/kserve
```

Install the Models web app:

```sh
kubectl apply -k contrib/kserve/models-web-app/overlays/kubeflow
```

- ../contrib/kserve/models-web-app/overlays/kubeflow

#### Katib

Install the Katib official Kubeflow component:

```sh
kubectl apply -k apps/katib/upstream/installs/katib-with-kubeflow
```

#### Central Dashboard

Install the Central Dashboard official Kubeflow component:

```sh
kubectl apply -k apps/centraldashboard/upstream/overlays/kserve
```

#### Admission Webhook

Install the Admission Webhook for PodDefaults:

```sh
kubectl apply -k apps/admission-webhook/upstream/overlays/cert-manager
```

#### Notebooks

Install the Notebook Controller official Kubeflow component:

```sh
kubectl apply -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
```

Install the Jupyter Web App official Kubeflow component:

```sh
kubectl apply -k apps/jupyter/jupyter-web-app/upstream/overlays/istio
```

#### Profiles + KFAM

Install the Profile Controller and the Kubeflow Access-Management (KFAM) official Kubeflow
components:

```sh
kubectl apply -k apps/profiles/upstream/overlays/kubeflow
```

#### Volumes Web App

Install the Volumes Web App official Kubeflow component:

```sh
kubectl apply -k apps/volumes-web-app/upstream/overlays/istio
```

#### Tensorboard

Install the Tensorboards Web App official Kubeflow component:

```sh
kubectl apply -k apps/tensorboard/tensorboards-web-app/upstream/overlays/istio
```

Install the Tensorboard Controller official Kubeflow component:

```sh
kubectl apply -k apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow
```

#### Training Operator

Install the Training Operator official Kubeflow component:

```sh
kubectl apply -k apps/training-operator/upstream/overlays/kubeflow
```

#### User Namespace

Finally, create a new namespace for the the default user (named `kubeflow-user-example-com`).

```sh
kubectl apply -k common/user-namespace/base
```

### Connect to your Kubeflow Cluster

To check that all Kubeflow-related Pods are ready, use the following commands:

```sh
kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-eventing
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com
```

**Port-Forward**

The default way of accessing Kubeflow is via `port-forward`. Run the following to port-forward Istio's Ingress-Gateway to local port 8080:

```sh
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
```
After running the command, you can access the Kubeflow Central Dashboard by doing the following:

- Visit `http://localhost:8080` and login with the default user's credential. 
- The default email address is `user@example.com` and the default password is `12341234`.

**NodePort / LoadBalancer / Ingress**

In order to connect to Kubeflow using NodePort / LoadBalancer / Ingress, you need to setup HTTPS. The reason is that many of our web apps (e.g., Tensorboard Web App, Jupyter Web App, Katib UI) use [Secure Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies), so accessing Kubeflow with HTTP over a non-localhost domain does not work.

Exposing your Kubeflow cluster with proper HTTPS is a process heavily dependent on your environment. For this reason, please take a look at the available Kubeflow distributions, which are targeted to specific environments, and select the one that fits your needs.

### Change default user password

- Edit `common/dex/base/config-map.yaml` and fill the relevant field with the hash of the password you chose:

```yaml
...
  staticPasswords:
  - email: user@example.com
    hash: <enter the generated hash here>
```

## Uninstall

```sh
source ./uninstall.sh
```

## Note
> use HTTP for dev
- Replace `true` if using `https` instead of `http`
    - change three places by doing the following:
    
    ```yaml
    # apps/jupyter/jupyter-web-app/upstream/base/params.env
    JWA_APP_SECURE_COOKIES=true
    # apps/jupyter/jupyter-web-app/upstream/base/params.env
    TWA_APP_SECURE_COOKIES=true
    # apps/volumes-web-app/upstream/base/params.env
    VWA_APP_SECURE_COOKIES=true
    ```


## Reference

- [Kubeflow Installation Options](https://www.kubeflow.org/docs/components/pipelines/v1/installation/overview/)