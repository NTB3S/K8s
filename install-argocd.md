Certainly! Here's a simplified README.md focusing on the installation steps for Argo CD without steps 3 and 4:

---

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

### Step 2: Apply Installation Manifest

Apply the Argo CD installation manifest:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
### Step 3: Exposing with Nginx Ingress

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
