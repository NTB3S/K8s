# Argo CD Installation Guide

## Overview

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes applications. Follow these steps to install Argo CD on your Kubernetes cluster.

## Prerequisites

Before you begin, ensure you have:

- A Kubernetes cluster (version 1.16+ recommended)
- `kubectl` command-line tool installed and configured to access your cluster
- Cluster admin access to install Argo CD components

## Installation Steps

### Step 1: Create Namespace

Create a namespace for Argo CD:

```bash
kubectl create namespace argocd
```

### Step 2: Installation

#### Step 2.1 : Manifest

Apply the Argo CD installation manifest:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### Step 2.2: Helm

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm search repo argo
helm install argocd argo/argo-cd --namespace argocd
```


### Step 3: Exposing with Nginx Ingress
Based on the [argocd documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/) you have to edit the argocd-server deployment and and the both bellow flags :
```bash
- --insecure
- --rootpath=/argocd
```

Or you can use the argocd-values.yaml when you install the chart to enable it.


   Given our Kubernetes cluster is divided into multiple namespaces, use Nginx Ingress to expose services across namespaces. Refer to this guide for detailed setup:
   [Routing Ingress Traffic Across Namespaces](https://tech.aabouzaid.com/2022/08/2-ways-to-route-ingress-traffic-across-namespaces.html)

   Alternatively, use the following manifests to configure Ingress:

   **Master Ingress:**

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ingress-master
     annotations:
       nginx.org/mergeable-ingress-type: "master"
   spec:
     ingressClassName: nginx
     rules:
     - host: k8sbys3bstn.com
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: jenkins-service
               port:
                 number: 8080
   ```

   **Namespace-specific Ingress (e.g., for 'argocd' namespace):**

   ```yaml
   apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: argo-cd-ingress
    annotations:
        nginx.org/mergeable-ingress-type: "minion"
    spec:
    ingressClassName: nginx
    rules:
    - host: k8sbys3bstn.com
        http:
        paths:
        - path: /argocd
            pathType: Prefix
            backend:
            service:
                name: argocd-server
                port:
                number: 80
   ```

#### Applying Ingress Configurations

Apply the Ingress configurations using the following commands:

```bash
kubectl apply -f ./ingress/ingress-master.yaml
kubectl apply -f ./ingress/ingress-argocd.yaml
```

#### Applying Ingress Configurations

To retrieve the argoCD password you can use the following command : 

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
